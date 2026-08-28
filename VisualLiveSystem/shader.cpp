#include "shader.h"
#include <QByteArray>
#include <QDebug>
#include <QDir>
#include <QMessageBox>

namespace {

QString shaderObjectLog(GLhandleARB object)
{
    GLint length = 0;
    glGetObjectParameterivARB(object, GL_OBJECT_INFO_LOG_LENGTH_ARB, &length);
    if (length <= 1)
        return QString();

    QByteArray buffer(length, '\0');
    GLsizei written = 0;
    glGetInfoLogARB(object, length, &written, buffer.data());
    return QString::fromLocal8Bit(buffer.constData(), written).trimmed();
}

void showShaderError(const QString& title,
                     const QString& summary,
                     const QString& sourceName,
                     const QString& errorLog)
{
    const QString source = sourceName.isEmpty() ? QString("Unknown source") : sourceName;
    const QString details = errorLog.isEmpty()
        ? QString("The OpenGL driver did not provide a compiler log.")
        : errorLog;

    qCritical().noquote() << title << "\nSource:" << source << "\n" << details;

    QMessageBox message;
    message.setIcon(QMessageBox::Critical);
    message.setWindowTitle(title);
    message.setText(summary);
    message.setInformativeText(
        QString("Source:\n%1\n\nThis effect has been disabled. Select Show Details for the OpenGL driver output.")
            .arg(QDir::toNativeSeparators(source)));
    message.setDetailedText(details);
    message.exec();
}

}


//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
Shader::Shader()
    : m_program(0)
{

}
//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
Shader::~Shader()
{

}

//-----------------------------------------------------------------------------
// enable/disable
//-----------------------------------------------------------------------------
void Shader::enable()
{
    glUseProgramObjectARB(m_program);
}
void Shader::disable()
{
    glUseProgramObjectARB(0);
}


//-----------------------------------------------------------------------------
// send uniform
//-----------------------------------------------------------------------------
void Shader::sendi(const char *name, int x)
{
	glUniform1i(glGetUniformLocation(m_program,name), x);
}
void Shader::sendf(const char *name, float x)
{
	glUniform1f(glGetUniformLocation(m_program,name), x);
}
void Shader::sendf(const char *name, float x, float y)
{
    glUniform2f(glGetUniformLocation(m_program,name), x,y);
}
void Shader::sendf(const char *name, float x, float y, float z)
{
    glUniform3f(glGetUniformLocation(m_program,name), x,y,z);
}
void Shader::sendf(const char *name, float x, float y, float z, float w)
{
	glUniform4f(glGetUniformLocation(m_program,name), x,y,z,w);
}


//-----------------------------------------------------------------------------
// compil
//-----------------------------------------------------------------------------
int Shader::compil(const char *vertex, const char *fragment, const QString& sourceName)
{
    m_program = glCreateProgramObjectARB();
    QString errorLog;
	if (!makeShader(vertex, GL_VERTEX_SHADER_ARB, errorLog))
    {
		showShaderError("Vertex shader compilation failed",
		                "The built-in vertex shader could not be compiled.",
		                sourceName.isEmpty()
		                    ? QString("Built-in vertex shader")
		                    : QString("Built-in vertex shader used by %1").arg(sourceName),
		                errorLog);
		glDeleteObjectARB(m_program);
		m_program = 0;
		return SHADER_VERTEX_ERROR;
    }
	if (!makeShader(fragment, GL_FRAGMENT_SHADER_ARB, errorLog))
    {
		showShaderError("Fragment shader compilation failed",
		                "The fragment shader could not be compiled.",
		                sourceName,
		                errorLog);
		glDeleteObjectARB(m_program);
		m_program = 0;
		return SHADER_FRAGMENT_ERROR;
    }

	glLinkProgram(m_program);

	GLint linked = GL_FALSE;
	glGetObjectParameterivARB(m_program, GL_OBJECT_LINK_STATUS_ARB, &linked);
	if (!linked)
	{
		showShaderError("Shader program link failed",
		                "The compiled shaders could not be linked into a usable program.",
		                sourceName,
		                shaderObjectLog(m_program));
		glDeleteObjectARB(m_program);
		m_program = 0;
		return SHADER_FRAGMENT_ERROR;
	}

	return SHADER_SUCCESS;
}

bool Shader::makeShader(const char *txt, GLuint type, QString& errorLog)
{
    errorLog.clear();
    if (!txt || !txt[0])
    {
        errorLog = "The shader source is empty. The file may be missing or unreadable.";
        return false;
    }

    GLuint object = glCreateShaderObjectARB(type);
	if (!object)
	{
		errorLog = "OpenGL could not create a shader object.";
		return false;
	}

	glShaderSource(object, 1, (const GLchar**)(&txt), NULL);
	glCompileShader(object);
	
	//Check
    GLint ok = false;
    glGetObjectParameterivARB(object, GL_OBJECT_COMPILE_STATUS_ARB, &ok);

	if (!ok)
	{
		errorLog = shaderObjectLog(object);
		glDeleteObjectARB(object);
		return false;
	}

    glAttachObjectARB(m_program, object);
    glDeleteObjectARB(object);

	return true;
}






