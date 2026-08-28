#include <QTextStream>
#include <QtXml>
#include <QDir>
#include <QFileInfo>
#include <QMessageBox>
#include <iostream>
#include "../configpath.h"
#include "core.h"
#include "fast2dquad.h"
#include "scene.h"

Scene::Scene()
{
    m_id = 0;
    m_nbLayer = 0;
    m_layer = NULL;
    m_valid = false;
    m_time = 0.f;
    m_param[0] = QString("0");
    m_param[1] = QString("1");
    m_param[2] = QString("2");
    m_param[3] = QString("3");
    m_QTime.restart();
}

Scene::~Scene()
{
    for(int i=0; i<m_nbLayer; i++)
    {
        if(m_layer[i].buffer)
            delete m_layer[i].buffer;
        if(m_layer[i].backBuffer)
            delete m_layer[i].backBuffer;
        if(m_layer[i].shader)
            delete m_layer[i].shader;
        for(int j=0; j<4; j++)
            if(m_layer[i].channel[j])
                delete m_layer[i].channel[j];
    }
}


void Scene::read(const char *filename)
{
    m_valid = false;
    const QString sceneName = filename ? QString::fromLocal8Bit(filename) : QString("Open");
    const QDir sceneDirectory(QDir::current().filePath(QString("data/scenes/%1").arg(sceneName)));
    const QString configPath = QFileInfo(sceneDirectory.filePath("config.xml")).absoluteFilePath();

    //Parsing XML document.
    QDomDocument dom("config");
    QFile xml_doc(configPath);
    if(!xml_doc.open(QIODevice::ReadOnly))
    {
        QMessageBox::warning(
            NULL,
            "Scene configuration could not be opened",
            QString("Scene: %1\n\nFile:\n%2\n\nReason: %3\n\nThe scene will be skipped.")
                .arg(sceneName,
                     QDir::toNativeSeparators(configPath),
                     xml_doc.errorString()));
        return;
    }

    QString parseError;
    int parseLine = 0;
    int parseColumn = 0;
    if (!dom.setContent(&xml_doc, &parseError, &parseLine, &parseColumn))
    {
        xml_doc.close();
        QMessageBox::warning(
            NULL,
            "Scene configuration is invalid",
            QString("Scene: %1\n\nFile:\n%2\n\nXML error at line %3, column %4:\n%5\n\nThe scene will be skipped.")
                .arg(sceneName,
                     QDir::toNativeSeparators(configPath))
                .arg(parseLine)
                .arg(parseColumn)
                .arg(parseError));
        return;
    }

    //Count layers
    QDomNode node = dom.documentElement().firstChild();
    while(!node.isNull())
    {
        QDomElement element = node.toElement();
        if(element.tagName() == "layer")
            m_nbLayer++;
        node = node.nextSibling();
    }

    if (m_nbLayer <= 0)
    {
        QMessageBox::warning(
            NULL,
            "Scene configuration has no layers",
            QString("Scene: %1\n\nFile:\n%2\n\nNo <layer> elements were found. The scene will be skipped.")
                .arg(sceneName, QDir::toNativeSeparators(configPath)));
        return;
    }

    //Init new layers
    m_layer = new Layer[m_nbLayer];
    for(int i=0; i<m_nbLayer; i++)
    {
        m_layer[i].shader = NULL;
        m_layer[i].buffer = NULL;
        m_layer[i].backBuffer = NULL;
        m_layer[i].tmpBuffer = NULL;
        m_layer[i].mode = DEFAULT;
        for(int j=0; j<4; j++)
        {
            m_layer[i].channel[j] = NULL;
        }
    }

    //Read the xml file
    node = dom.documentElement().firstChild();
    int textureID=0;
    while(!node.isNull())
    {
        QDomElement element = node.toElement();
        if(element.tagName() == "layer")
        {
            //Get infos ..
            int id = element.attribute("id", "0").toInt();
            if (id < 0 || id >= m_nbLayer)
            {
                QMessageBox::warning(
                    NULL,
                    "Scene layer ID is invalid",
                    QString("Scene: %1\n\nFile:\n%2\n\nLayer ID %3 is outside the valid range 0 to %4. The scene will be skipped.")
                        .arg(sceneName, QDir::toNativeSeparators(configPath))
                        .arg(id)
                        .arg(m_nbLayer - 1));
                return;
            }
            QString format = element.attribute("format", "rgba");

            QString blend = element.attribute("mode", "default");
            m_layer[id].width = element.attribute("width", "-1").toInt();
            m_layer[id].height = element.attribute("height", "-1").toInt();

            if(m_layer[id].width == -1)
                m_layer[id].width = Core::instance()->getResX();
            if(m_layer[id].height == -1)
                m_layer[id].height = Core::instance()->getResY();

            if(blend != "default")
            {
                m_layer[id].tmpBuffer = new FBO();
                m_layer[id].tmpBuffer->setSize(m_layer[id].width, m_layer[id].height);
                m_layer[id].width = Core::instance()->getResX();
                m_layer[id].height = Core::instance()->getResY();
            }

            //Select format
            GLint bufferFormat = GL_RGBA;
            if(format == "rgb")
                bufferFormat = GL_RGB;
            else if(format == "rgba")
                bufferFormat = GL_RGBA;
            else if(format == "rgba32")
                bufferFormat = GL_RGBA32F_ARB; //TODOOOOOOO
            else if(format == "luminance")
                bufferFormat = GL_LUMINANCE;
            else
            {
                QMessageBox::warning(
                    NULL,
                    "Scene layer format is invalid",
                    QString("Scene: %1\nLayer: %2\n\nFile:\n%3\n\nUnsupported format: %4\n\nSupported formats: rgb, rgba, rgba32, luminance. The scene will be skipped.")
                        .arg(sceneName)
                        .arg(id)
                        .arg(QDir::toNativeSeparators(configPath), format));
                return;
            }

            //Select mode
            if(blend == "default")
                m_layer[id].mode = DEFAULT;
            else if(blend == "alpha")
                m_layer[id].mode = BLEND_ALPHA;
            else if(blend == "add")
                m_layer[id].mode = BLEND_ADD;
            else
            {
                QMessageBox::warning(
                    NULL,
                    "Scene layer mode is invalid",
                    QString("Scene: %1\nLayer: %2\n\nFile:\n%3\n\nUnsupported mode: %4\n\nSupported modes: default, alpha, add. The scene will be skipped.")
                        .arg(sceneName)
                        .arg(id)
                        .arg(QDir::toNativeSeparators(configPath), blend));
                return;
            }

            //Compute shader
            QString filePath = element.attribute("value", "none");
            int ok = SHADER_FRAGMENT_ERROR;
            if(filePath == "none")
            {
                QMessageBox::warning(
                    NULL,
                    "Scene shader is not specified",
                    QString("Scene: %1\n\nFile:\n%2\n\nLayer %3 has no shader file in its value attribute. The scene will be skipped.")
                        .arg(sceneName, QDir::toNativeSeparators(configPath))
                        .arg(id));
                return;
            }
            else
            {
                const QString shaderPath = ConfigPath::resolve(sceneDirectory, filePath);
                QFile file(shaderPath);
                QString strings;
                if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
                {
                    QMessageBox::warning(
                        NULL,
                        "Scene shader could not be opened",
                        QString("Scene: %1\nLayer: %2\n\nShader file:\n%3\n\nReason: %4\n\nThe scene will be skipped.")
                            .arg(sceneName)
                            .arg(id)
                            .arg(QDir::toNativeSeparators(shaderPath), file.errorString()));
                    return;
                }

                QTextStream in(&file);
                while (!in.atEnd()) {
                    strings += in.readLine()+"\n";
                }
                m_layer[id].shader = new Shader();
                ok = m_layer[id].shader->compil(Core::instance()->getVertexShader(),
                                                strings.toStdString().c_str(),
                                                shaderPath);
            }


            //Generate buffers !
            if(ok == SHADER_SUCCESS)
            {
                m_layer[id].buffer = new FBO();
                m_layer[id].buffer->setSize(m_layer[id].width, m_layer[id].height);
                m_layer[id].buffer->setFormat(bufferFormat);
                if(element.attribute("backbuffer", "false") == "true")
                {
                    m_layer[id].backBuffer = new FBO();
                    m_layer[id].backBuffer->setSize(m_layer[id].width, m_layer[id].height);
                    m_layer[id].backBuffer->setFormat(bufferFormat);
                }
            }
            else
            {
                delete m_layer[id].shader;
                m_layer[id].shader = NULL;
                return;
            }

            //Load channel
            textureID=0;
            QDomNode n = element.firstChild();
            while(!n.isNull())
            {
                QDomElement e = n.toElement();
                if(e.tagName() == "channel")
                {
                    if(textureID<4)
                    {
                        m_layer[id].channelName[textureID] = e.attribute("id", "tex");
                        if( e.attribute("type", "") == "image" )
                        {
                            m_layer[id].channel[textureID] = new Texture();
                            const QDir textureDirectory(QDir::current().filePath("data/textures"));
                            const QString texturePath = ConfigPath::resolve(
                                textureDirectory, e.attribute("value", "none"));
                            m_layer[id].channel[textureID]->load(texturePath.toStdString());
                        }
                        else if( e.attribute("type", "") == "layer" )
                        {
                            m_layer[id].channel[textureID] = m_layer[e.attribute("value", "0").toInt()].buffer;
                            m_layer[e.attribute("value", "0").toInt()].buffer->bind();
                        }
                        textureID++;
                    }
                    else
                    {
                        QMessageBox::warning(
                            NULL,
                            "Scene has too many texture channels",
                            QString("Scene: %1\nLayer: %2\n\nFile:\n%3\n\nA layer can use at most four <channel> elements. The scene will be skipped.")
                                .arg(sceneName)
                                .arg(id)
                                .arg(QDir::toNativeSeparators(configPath)));
                        return;
                    }
                }
                n = n.nextSibling();
            }
        }
        else if(element.tagName() == "param")
        {
            const int parameterId = element.attribute("id", "0").toInt();
            if (parameterId < 0 || parameterId >= 4)
            {
                QMessageBox::warning(
                    NULL,
                    "Scene parameter ID is invalid",
                    QString("Scene: %1\n\nFile:\n%2\n\nParameter ID %3 is outside the valid range 0 to 3. The scene will be skipped.")
                        .arg(sceneName, QDir::toNativeSeparators(configPath))
                        .arg(parameterId));
                return;
            }
            m_param[parameterId] = element.attribute("value","none");
        }
        node = node.nextSibling();
    }

    m_valid = true;
}

void Scene::resetTime()
{
    m_time = 0.f;
}

void Scene::compute()
{
    if (!m_valid)
        return;

    m_time += float(m_QTime.elapsed())*0.001f*Core::instance()->getTimeSpeed();
    m_QTime.restart();

    for(int i=0; i<m_nbLayer; i++)
    {
        //Enable fbo
        if(m_layer[i].mode == DEFAULT)
            m_layer[i].buffer->enable();
        else
            m_layer[i].tmpBuffer->enable();

            m_layer[i].shader->enable();
            for(int j=0; j<4; j++)
            {
                if(m_layer[i].channel[j] != NULL)
                {
                    glActiveTexture(GL_TEXTURE0+j);
                    m_layer[i].channel[j]->bind();
                    m_layer[i].shader->sendi(m_layer[i].channelName[j].toStdString().c_str(), j);
                }
            }
                if(i>0)
                {
                    glActiveTexture(GL_TEXTURE4);
                    m_layer[i].shader->sendi("lastBuffer",4);
                    glBindTexture(GL_TEXTURE_2D, m_layer[i-1].buffer->getColor());
                }
                if(m_layer[i].backBuffer)
                {
                    glActiveTexture(GL_TEXTURE5);
                    m_layer[i].shader->sendi("backBuffer",5);
                    glBindTexture(GL_TEXTURE_2D, m_layer[i].backBuffer->getColor());
                }

                glActiveTexture(GL_TEXTURE6);
                Core::instance()->bindTextureSpectrum();
                m_layer[i].shader->sendi("spectrum",6);

                m_layer[i].shader->sendf("bass",Core::instance()->getBass());
                m_layer[i].shader->sendf("noise_lvl",Core::instance()->getNoiseLvl());
                m_layer[i].shader->sendf("bassTime",Core::instance()->getBassTime());
                m_layer[i].shader->sendf("time",m_time);
                m_layer[i].shader->sendf("CC[0]", Core::instance()->getCC(m_id,0));
                m_layer[i].shader->sendf("CC[1]", Core::instance()->getCC(m_id,1));
                m_layer[i].shader->sendf("CC[2]", Core::instance()->getCC(m_id,2));
                m_layer[i].shader->sendf("CC[3]", Core::instance()->getCC(m_id,3));


                glEnable(GL_TEXTURE_3D);
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_3D, Core::instance()->getNoise3D());
                m_layer[i].shader->sendi("noise3D",0);
                Fast2DQuadDraw();
                glBindTexture(GL_TEXTURE_3D, 0);
                glDisable(GL_TEXTURE_3D);



                glActiveTexture(GL_TEXTURE6);
                glBindTexture(GL_TEXTURE_1D, 0);
                for(int j=5; j<=0; j--)
                {
                    glActiveTexture(GL_TEXTURE0+j);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    if(j<4)
                    {
                        /*if(m_texture[j].getName() == "noise3D")
                        {
                        }*/
                    }
                }

            m_layer[i].shader->disable();

        if(m_layer[i].mode == DEFAULT)
            m_layer[i].buffer->disable();
        else
        {
            m_layer[i].tmpBuffer->disable();

            m_layer[i].buffer->enable();
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, m_layer[(int)fmax(i-1,0)].buffer->getColor());
                Fast2DQuadDraw();

                glEnable(GL_BLEND);
                if(m_layer[i].mode == BLEND_ALPHA)
                    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                else //if(m_layer[i].mode == BLEND_ADD)
                    glBlendFunc(GL_ONE, GL_ONE);
                glBindTexture(GL_TEXTURE_2D, m_layer[i].tmpBuffer->getColor());
                Fast2DQuadDraw();
                glDisable(GL_BLEND);

            m_layer[i].buffer->disable();

        }



        //Compute back buffer if needed..
        if(m_layer[i].backBuffer)
        {
            m_layer[i].backBuffer->enable();
                glActiveTexture(GL_TEXTURE0);
                if(m_layer[i].mode == DEFAULT)
                    glBindTexture(GL_TEXTURE_2D, m_layer[i].buffer->getColor());
                else
                    glBindTexture(GL_TEXTURE_2D, m_layer[i].tmpBuffer->getColor());
                Fast2DQuadDraw();
            m_layer[i].backBuffer->disable();
        }

    }
    glDisable(GL_TEXTURE_1D);
}

void Scene::draw()
{
    if (!m_valid)
        return;

    if(m_nbLayer>0)
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, m_layer[m_nbLayer-1].buffer->getColor());
        Fast2DQuadDraw();
    }
}

void Scene::setPreview(bool t)
{
    if (!m_valid)
        return;

    if(t)
    {
        for(int i=0; i<m_nbLayer; i++)
        {
            if(m_layer[i].buffer)
                m_layer[i].buffer->setSize( m_layer[i].width/8, m_layer[i].height/8);
            if(m_layer[i].backBuffer)
                m_layer[i].backBuffer->setSize( m_layer[i].width/8, m_layer[i].height/8);
            if(m_layer[i].tmpBuffer)
                m_layer[i].tmpBuffer->setSize( m_layer[i].width/8, m_layer[i].height/8);
        }
    }
    else
    {
        for(int i=0; i<m_nbLayer; i++)
        {
            if(m_layer[i].buffer)
                m_layer[i].buffer->setSize( m_layer[i].width, m_layer[i].height);
            if(m_layer[i].backBuffer)
                m_layer[i].backBuffer->setSize( m_layer[i].width, m_layer[i].height);
            if(m_layer[i].tmpBuffer)
                m_layer[i].tmpBuffer->setSize( m_layer[i].width, m_layer[i].height);
        }
    }
    glFlush();
    glFinish();
}
