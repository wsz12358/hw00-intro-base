#version 300 es

// 自定义片段着色器，为波浪变形的立方体提供着色
precision highp float;

uniform vec4 u_Color; // 渲染颜色

// 从顶点着色器插值得到的值
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // 最终输出颜色

void main()
{
    // 材质基础颜色
    vec4 diffuseColor = u_Color;

    // 计算兰伯特着色的漫反射项
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // 避免负的光照值
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   // 添加环境光照

    // 计算最终着色颜色
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
