
// Raspi-Splash Main 
// requires "./pidora-logo-cmyk.TGA" to be in the 
// same directory as the executable
/* This script is written by Ai Dow, Nov 2013 */



#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "esUtil.h"

void ShutDown ( ESContext *esContext );

GLfloat g_Vertices[20] = { -1.0f,  0.5f, 0.0f,  // Position 0
                         0.0f,  1.0f,        // TexCoord 0 
                        -1.0f, -0.5f, 0.0f,  // Position 1
                         0.0f,  0.0f,        // TexCoord 1
                         1.0f, -0.5f, 0.0f,  // Position 2
                         1.0f,  0.0f,        // TexCoord 2
                         1.0f,  0.5f, 0.0f,  // Position 3
                         1.0f,  1.0f         // TexCoord 3
                        };
GLushort g_indices[6] = { 0, 1, 2, 0, 2, 3 };	

typedef struct
{
   // Handle to a program object
   GLuint programObject;

   // Attribute locations
   GLint  positionLoc;
   GLint  texCoordLoc;
   GLint  mvpLoc;

   // Sampler location
   GLint samplerLoc;

   // Texture handle
   GLuint textureId;
   
   ESMatrix  mvpMatrix;
   GLfloat angle;
   GLfloat xpos;
   GLfloat ypos;
   GLfloat zpos;
   GLfloat time;	

} UserData;

///
// Create a the raspi-splash texture
//
GLuint CreateRaspiTexture2D( )
{
   // Texture object handle
   GLuint textureId;
   
   // Use tightly packed data
   //glPixelStorei ( GL_UNPACK_ALIGNMENT, 1 );

   GLint logoWidth;
   GLint logoHeight;	
   char logoFilename[256];	
   char* pixels;
   
   // these were used to map different color spaces	
   // I still have the problem of an usuported pixel format
   // there are three seperated transform all jumbled togeter
   // and commented out. They are being kept in the code for
   // experimentation.
   char R,G,B;
   float K,C,M,Y;
   float sR,sG,sB,a;
   int i,j;	
   	 

   bzero(logoFilename, 256 * sizeof(char));
   snprintf(logoFilename, 250, "%s","/usr/bin/pidora-logo-cmyk.TGA");
 
   pixels = esLoadTGA(logoFilename,&logoWidth,&logoHeight);
   if (pixels == NULL)
      return ;		

    // experiments to determine
    // supported color spaces in
    // opengl es 2.0
    // different color spaces are supported in
    // opengl,opengl es 2.0 and opengl es 3.0
        
   //for(i=0;i<logoWidth*logoHeight;i++)
   //{
	//K = (float)pixels[i*4 + 0];
        //C = (float)pixels[i*4 + 1];
        //M = (float)pixels[i*4 + 2];
        //Y = (float)pixels[i*4 + 3];
        
	//R = (char)((255.0-C)*(1.0-K/255.0));
        //G = (char)((255.0-M)*(1.0-K/255.0));
        //B = (char)((255.0-Y)*(1.0-K/255.0));
   
        //for(j = 0; j < 3; j ++)
        //{
        ///    C = ((float)pixels[i*4 + j])/255.0;
        
        //    if (C > 0.04045){
        //        K = pow((C +0.035)/(1+0.035),4.4);
            
        //    }
        //    else{
        //        K = C/12.92;
        //    }
            
        //    pixels[i*4 + j] = (char)(K*255.0);
        //}
        //pixels[i*4 + 0] = R;
        //pixels[i*4 + 1] = G;
        //pixels[i*4 + 2] = B;
       //  if((pixels[i*4 + 0]>240)&&(pixels[i*4 + 1]>240)&&(pixels[i*4 + 2]>240))
       //  {
		//pixels[i*4+0] = 0;
		//pixels[i*4 + 1]=0;
		//pixels[i*4 + 2]=0;
	//} 
	//    pixels[i*4 + 3] = 255;
        
       // C = (float)pixels[i*4 + 0];
       // M = (float)pixels[i*4 + 1];
       // Y = (float)pixels[i*4 + 2];
       
        //pixels[i*4 + 0] = (char)(0.4121*C + 0.3576*M + 0.1805*Y);
        //pixels[i*4 + 1] = (char)(0.2126*C + 0.7152*M + 0.0722*Y);
        //pixels[i*4 + 2] = (char)(0.0193*C + 0.1192*M + 0.9505*Y);

   //}
   // Generate a texture object
   glGenTextures ( 1, &textureId );

   // Bind the texture object
   glBindTexture ( GL_TEXTURE_2D, textureId );

   // Load the texture
   //glTexImage2D ( GL_TEXTURE_2D, 0, GL_RGB, 2, 2, 0, GL_RGB, GL_UNSIGNED_BYTE, pixels );
   glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,logoWidth,logoHeight,
		  0,GL_RGBA,GL_UNSIGNED_BYTE,pixels);

   // Set the filtering mode
   glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
   glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );

   return textureId;

}


///
// Initialize the shader and program object
//
int Init ( ESContext *esContext )
{
   esContext->userData = malloc(sizeof(UserData));	
   UserData *userData = esContext->userData;
   
   GLbyte vShaderStr[] = 
      "uniform mat4 u_mvpMatrix;    \n" 
      "attribute vec4 a_position;   \n"
      "attribute vec2 a_texCoord;   \n"
      "varying vec2 v_texCoord;     \n"
      "void main()                  \n"
      "{                            \n"
      "   gl_Position = u_mvpMatrix * a_position;  \n"
      "   v_texCoord = a_texCoord;  \n"
      "}                            \n";
   
   GLbyte fShaderStr[] =  
      "precision mediump float;                            \n"
      "varying vec2 v_texCoord;                            \n"
      "uniform sampler2D s_texture;                        \n"
      "void main()                                         \n"
      "{                                                   \n"
      "  gl_FragColor = texture2D( s_texture, v_texCoord );\n"
      "}                                                   \n";

   // Load the shaders and get a linked program object
   userData->programObject = esLoadProgram ( vShaderStr, fShaderStr );

   // Get the attribute locations
   userData->positionLoc = glGetAttribLocation ( userData->programObject, "a_position" );
   userData->texCoordLoc = glGetAttribLocation ( userData->programObject, "a_texCoord" );
   userData->mvpLoc = glGetUniformLocation( userData->programObject, "u_mvpMatrix" );
   
   // Get the sampler location
   userData->samplerLoc = glGetUniformLocation ( userData->programObject, "s_texture" );

   // Load the texture
   userData->textureId = CreateRaspiTexture2D ();
   esMatrixLoadIdentity( &userData->mvpMatrix );

   userData->xpos = 0.0; 
   userData->angle= 0.0;
   userData->time = 0.0; 
  		
  // printf("%f \n",userData->xpos);
   glClearColor ( 0.0f, 0.0f, 0.0f, 1.0f );
   return GL_TRUE;
}


void Update ( ESContext *esContext, float deltaTime )
{
    UserData *userData = (UserData*) esContext->userData;
    ESMatrix perspective;
    ESMatrix modelview;
    float    aspect;
  
    //userData->time += deltaTime; 
    
    //if(userData->time > 2.0)
	//    ShutDown(esContext);

  
   // printf("%f \n",userData->time); 
   // Compute a rotation angle based on time between frames
    userData->angle += ( deltaTime * 60.0f );
  
    if( userData->angle >= 360.0f )
        userData->angle -= 360.0f;

   
    userData->xpos += 0.01;		 
    
    if(userData->xpos > 1.7)
		userData->xpos = -1.5;

    // Compute the window aspect ratio
    aspect = (GLfloat) esContext->width / (GLfloat) esContext->height;
   
    // Generate a perspective matrix with a 60 degree FOV
    esMatrixLoadIdentity( &perspective );
    //esPerspective( &perspective, 60.0f, aspect, 1.0f, 20.0f );

    // Generate a model view matrix to rotate/translate the cube
    esMatrixLoadIdentity( &modelview );

    // Translate away from the viewer
    esTranslate( &modelview, userData->xpos,0.0,0.0 );

    // Rotate the cube
    esRotate( &modelview, userData->angle, 1.0, 0.0, 0.0 );
   
    // Compute the final MVP by multiplying the 
    // modevleiw and perspective matrices together
    esMatrixMultiply( &userData->mvpMatrix, &modelview, &perspective );
}

///
// Draw a triangle using the shader pair created in Init()
//
void Draw ( ESContext *esContext )
{
   UserData *userData = esContext->userData;
 
   // Set the viewport
   glViewport ( 0, 0, esContext->width, esContext->height );
   
   // Clear the color buffer
   glClear ( GL_COLOR_BUFFER_BIT );

   // Use the program object
   glUseProgram ( userData->programObject );

   // Load the vertex position
   glVertexAttribPointer ( userData->positionLoc, 3, GL_FLOAT, 
                           GL_FALSE, 5 * sizeof(GLfloat), g_Vertices );
   // Load the texture coordinate
   glVertexAttribPointer ( userData->texCoordLoc, 2, GL_FLOAT,
                           GL_FALSE, 5 * sizeof(GLfloat), &g_Vertices[3] );

   glEnableVertexAttribArray ( userData->positionLoc );
   glEnableVertexAttribArray ( userData->texCoordLoc );

   // Bind the texture
   glActiveTexture ( GL_TEXTURE0 );
   glBindTexture ( GL_TEXTURE_2D, userData->textureId );

   // Set the sampler texture unit to 0
   glUniform1i ( userData->samplerLoc, 0 );
   
      // Load the MVP matrix
   glUniformMatrix4fv( userData->mvpLoc, 1, GL_FALSE, (GLfloat*) &userData->mvpMatrix.m[0][0] );

   glDrawElements ( GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, g_indices );
  // eglSwapBuffers(esContext->eglDisplay, esContext->eglSurface);
}
///
//redraw
///
// Cleanup
//
void ShutDown ( ESContext *esContext )
{
   UserData *userData = esContext->userData;

   // Delete texture object
   glDeleteTextures ( 1, &userData->textureId );

   // Delete program object
   glDeleteProgram ( userData->programObject );
	
   free(esContext->userData);
}

int main ( int argc, char *argv[] )
{
   ESContext esContext;
   UserData  userData;

   esInitContext ( &esContext );
   esContext.userData = &userData;

   esCreateWindow ( &esContext, "Raspi-Splash",  ES_WINDOW_RGB );

   if ( !Init ( &esContext ) )
      return 0;

   // pass a pointer to the Draw fuction to be called 
   // in esMainLoop 
   esRegisterDrawFunc ( &esContext, Draw );
   esRegisterUpdateFunc ( &esContext, Update );

   esMainLoop ( &esContext );

   ShutDown ( &esContext );
}
