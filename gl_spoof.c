#define _GNU_SOURCE
#include <dlfcn.h>
#include <GL/gl.h>
#include <string.h>

typedef const GLubyte* (*real_glGetString_t)(GLenum name);
static real_glGetString_t real_glGetString = NULL;

const GLubyte* glGetString(GLenum name) {
    if (!real_glGetString) {
        real_glGetString = (real_glGetString_t)dlsym(RTLD_NEXT, "glGetString");
    }
    switch (name) {
        case GL_VENDOR:
            return (const GLubyte*)"NVIDIA Corporation";
        case GL_RENDERER:
            return (const GLubyte*)"NVIDIA GeForce GTX 1080/PCIe/SSE2";
        default:
            return real_glGetString(name);
    }
}

typedef const GLubyte* (*real_glGetStringi_t)(GLenum name, GLuint index);
static real_glGetStringi_t real_glGetStringi = NULL;

const GLubyte* glGetStringi(GLenum name, GLuint index) {
    if (!real_glGetStringi) {
        real_glGetStringi = (real_glGetStringi_t)dlsym(RTLD_NEXT, "glGetStringi");
    }
    return real_glGetStringi(name, index);
}
