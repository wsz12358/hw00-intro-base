#version 300 es

//自定义顶点着色器，使用三角函数对立方体顶点位置进行时间相关的变形

uniform mat4 u_Model;       // 模型矩阵
uniform mat4 u_ModelInvTr;  // 模型矩阵的逆转置
uniform mat4 u_ViewProj;    // 视图投影矩阵
uniform float u_Time;       // 时间变量，用于动画

in vec4 vs_Pos;             // 顶点位置
in vec4 vs_Nor;             // 顶点法线
in vec4 vs_Col;             // 顶点颜色

out vec4 fs_Nor;            // 输出到片段着色器的法线
out vec4 fs_LightVec;       // 输出到片段着色器的光照向量
out vec4 fs_Col;            // 输出到片段着色器的颜色

const vec4 lightPos = vec4(5, 5, 3, 1); // 光源位置

void main()
{
    fs_Col = vs_Col;                         // 传递顶点颜色

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // 传递变换后的法线

    // 获取原始顶点位置
    vec4 originalPos = vs_Pos;
    
    // 使用三角函数对顶点位置进行非均匀变形
    // 基于顶点的x和z坐标以及时间创建波浪效果
    // float waveX = sin(originalPos.x * 3.0 + u_Time * 2.0) * 0.3;
    // float waveZ = cos(originalPos.z * 3.0 + u_Time * 1.5) * 0.2;
    float waveY = sin(originalPos.y * 2.0 + u_Time * 3.0) * 0.15;
    
    // 创建一个复合波浪效果
    float combinedWave = sin(originalPos.x * 10.0 + originalPos.z * 10.0 + u_Time * 2.5) * 0.5;
    
    // 应用变形到顶点位置
    vec4 deformedPos = originalPos;
    deformedPos.x += originalPos.x;
    deformedPos.y += combinedWave;
    deformedPos.z += originalPos.z;

    vec4 modelposition = u_Model * deformedPos;   // 应用模型变换到变形后的位置

    fs_LightVec = lightPos - modelposition;  // 计算光照方向

    gl_Position = u_ViewProj * modelposition;// 最终顶点位置
}
