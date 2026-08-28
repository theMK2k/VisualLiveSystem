#include <QTextStream>
#include <QtXml>
#include <QDir>
#include <QFileInfo>
#include <QMessageBox>
#include <iostream>
#include "../configpath.h"
#include "core.h"
#include "fast2dquad.h"
#include "transition.h"

Transition::Transition()
{
    m_shader = NULL;
    m_backBuffer = NULL;
    m_time.restart();

    m_totalTime = 1.f;
    m_switchTime = 0.f;
    m_switched = false;
}

Transition::~Transition()
{
    if(m_backBuffer)
        delete m_backBuffer;
    if(m_shader)
        delete m_shader;
}

void Transition::read(const char *filename)
{
    const QString transitionName = filename ? QString::fromLocal8Bit(filename) : QString("Unknown transition");
    const QDir transitionDirectory(
        QDir::current().filePath(QString("data/transitions/%1").arg(transitionName)));
    const QString configPath = QFileInfo(transitionDirectory.filePath("config.xml")).absoluteFilePath();

    //Parsing XML document.
    QDomDocument dom("config");
    QFile xml_doc(configPath);
    if(!xml_doc.open(QIODevice::ReadOnly))
    {
        QMessageBox::warning(
            NULL,
            "Transition configuration could not be opened",
            QString("Transition: %1\n\nFile:\n%2\n\nReason: %3\n\nThe transition will be skipped.")
                .arg(transitionName,
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
            "Transition configuration is invalid",
            QString("Transition: %1\n\nFile:\n%2\n\nXML error at line %3, column %4:\n%5\n\nThe transition will be skipped.")
                .arg(transitionName, QDir::toNativeSeparators(configPath))
                .arg(parseLine)
                .arg(parseColumn)
                .arg(parseError));
        return;
    }
    QDomNode node = dom.documentElement().firstChild();
    while(!node.isNull())
    {
        QDomElement element = node.toElement();

        if(element.tagName() == "time")
        {
            m_totalTime = element.attribute("total", "1").toFloat();
            m_switchTime = element.attribute("switch", "0").toFloat();
        }
        else if(element.tagName() == "pass")
        {
            //Compute shader
            QString filePath = element.attribute("value", "none");
            int ok = SHADER_FRAGMENT_ERROR;
            if(filePath == "none")
            {
                QMessageBox::warning(
                    NULL,
                    "Transition shader is not specified",
                    QString("Transition: %1\n\nFile:\n%2\n\nThe <pass> element has no shader file in its value attribute. The transition will be skipped.")
                        .arg(transitionName, QDir::toNativeSeparators(configPath)));
                return;
            }
            else
            {
                const QString shaderPath = ConfigPath::resolve(transitionDirectory, filePath);
                QFile file(shaderPath);
                QString strings;
                if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
                {
                    QMessageBox::warning(
                        NULL,
                        "Transition shader could not be opened",
                        QString("Transition: %1\n\nShader file:\n%2\n\nReason: %3\n\nThe transition will be skipped.")
                            .arg(transitionName,
                                 QDir::toNativeSeparators(shaderPath),
                                 file.errorString()));
                    return;
                }

                QTextStream in(&file);
                while (!in.atEnd()) {
                    strings += in.readLine()+"\n";
                }
                m_shader = new Shader();
                ok = m_shader->compil(Core::instance()->getVertexShader(),
                                      strings.toStdString().c_str(),
                                      shaderPath);
            }


            //Generate buffers !
            if(ok == SHADER_SUCCESS)
            {
                if(element.attribute("backbuffer", "false") == "true")
                {
                    m_backBuffer = new FBO();
                    m_backBuffer->setSize(Core::instance()->getResX(), Core::instance()->getResY());
                }
            }
            else
            {
                delete m_shader;
                m_shader = NULL;
                return;
            }
        }
        node = node.nextSibling();
    }
}

void Transition::start()
{
    m_time.restart();
    m_switched = false;
}

void Transition::draw()
{
    if (!m_shader)
        return;

    float time = float(m_time.elapsed())/1000.f;

    glEnable(GL_TEXTURE_1D);
    if(time < m_totalTime)
    {
        m_shader->enable();
            if(time < m_switchTime)
            {
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, Core::instance()->getFBOChan(Core::instance()->getCurrentChannel())->getColor());
                m_shader->sendi("first",0);
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, Core::instance()->getFBOChan(!Core::instance()->getCurrentChannel())->getColor());
                m_shader->sendi("second",1);
            }
            else
            {
                if(!m_switched)
                {
                    m_switched = true;
                    Core::instance()->Switch();
                }
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, Core::instance()->getFBOChan(!Core::instance()->getCurrentChannel())->getColor());
                m_shader->sendi("first",0);
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, Core::instance()->getFBOChan(Core::instance()->getCurrentChannel())->getColor());
                m_shader->sendi("second",1);
            }

            glActiveTexture(GL_TEXTURE2);
            Core::instance()->bindTextureSpectrum();
            m_shader->sendi("spectrum",2);

            m_shader->sendf("bass",Core::instance()->getBass());
            m_shader->sendf("bassTime",Core::instance()->getBassTime());
            m_shader->sendf("time",time);


            Fast2DQuadDraw();

            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_1D, 0);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, 0);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, 0);

        m_shader->disable();
    }
    else
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, Core::instance()->getFBOChan(Core::instance()->getCurrentChannel())->getColor());
        Fast2DQuadDraw();
    }
}
