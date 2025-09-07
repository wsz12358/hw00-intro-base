#version 300 es

// Perlin noise vertex shader
// This vertex shader will apply time-based deformation using trigonometric functions
// and pass 3D world position to fragment shader for Perlin noise calculation

uniform mat4 u_Model;       // Model transformation matrix
uniform mat4 u_ModelInvTr;  // Inverse transpose of model matrix for normals
uniform mat4 u_ViewProj;    // View-projection matrix
// Removed u_Time uniform - no time-based animation needed

in vec4 vs_Pos;             // Vertex positions
in vec4 vs_Nor;             // Vertex normals
in vec4 vs_Col;             // Vertex colors

out vec4 fs_Nor;            // Transformed normals to fragment shader
out vec4 fs_LightVec;       // Light direction to fragment shader
out vec4 fs_Col;            // Vertex colors to fragment shader
out vec4 fs_Pos;            // World position to fragment shader (for 3D noise)

const vec4 lightPos = vec4(5, 5, 3, 1); // Light position

void main()
{
    fs_Col = vs_Col;
    
    // Transform normals
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);
    
    // No vertex deformation - keep original positions
    // Transform to world space
    vec4 modelposition = u_Model * vs_Pos;
    fs_Pos = modelposition; // Pass world position to fragment shader
    
    // Calculate light direction
    fs_LightVec = lightPos - modelposition;
    
    // Final vertex position
    gl_Position = u_ViewProj * modelposition;
}