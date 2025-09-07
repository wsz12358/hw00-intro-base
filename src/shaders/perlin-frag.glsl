#version 300 es

// Perlin noise fragment shader
// This fragment shader implements 3D Perlin noise to modify fragment colors

precision highp float;

uniform vec4 u_Color;       // Base color
// No time uniform needed for static rust effect

// Input from vertex shader
in vec4 fs_Nor;             // Interpolated normals
in vec4 fs_LightVec;        // Light direction
in vec4 fs_Col;             // Vertex colors
in vec4 fs_Pos;             // World position for 3D noise

out vec4 out_Col;           // Final output color

// Hash function for generating pseudo-random values
float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

// Get 3D gradient vector for Perlin noise
vec3 getGradient3D(vec3 p) {
    // 12 predefined gradient vectors pointing to cube edge midpoints
    vec3 gradients[12] = vec3[](
        vec3( 1.0,  1.0,  0.0), vec3(-1.0,  1.0,  0.0), 
        vec3( 1.0, -1.0,  0.0), vec3(-1.0, -1.0,  0.0),
        vec3( 1.0,  0.0,  1.0), vec3(-1.0,  0.0,  1.0), 
        vec3( 1.0,  0.0, -1.0), vec3(-1.0,  0.0, -1.0),
        vec3( 0.0,  1.0,  1.0), vec3( 0.0, -1.0,  1.0), 
        vec3( 0.0,  1.0, -1.0), vec3( 0.0, -1.0, -1.0)
    );
    
    // Use hash to select gradient index
    int index = int(hash(p) * 12.0) % 12;
    return gradients[index];
}

// Smooth interpolation function (quintic)
vec3 fade(vec3 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// 3D Perlin noise function
float perlin3D(vec3 p) {
    // Get integer and fractional parts
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    // Get gradients for 8 cube corners
    vec3 g000 = getGradient3D(i + vec3(0.0, 0.0, 0.0));
    vec3 g100 = getGradient3D(i + vec3(1.0, 0.0, 0.0));
    vec3 g010 = getGradient3D(i + vec3(0.0, 1.0, 0.0));
    vec3 g110 = getGradient3D(i + vec3(1.0, 1.0, 0.0));
    vec3 g001 = getGradient3D(i + vec3(0.0, 0.0, 1.0));
    vec3 g101 = getGradient3D(i + vec3(1.0, 0.0, 1.0));
    vec3 g011 = getGradient3D(i + vec3(0.0, 1.0, 1.0));
    vec3 g111 = getGradient3D(i + vec3(1.0, 1.0, 1.0));
    
    // Calculate dot products
    float n000 = dot(g000, f - vec3(0.0, 0.0, 0.0));
    float n100 = dot(g100, f - vec3(1.0, 0.0, 0.0));
    float n010 = dot(g010, f - vec3(0.0, 1.0, 0.0));
    float n110 = dot(g110, f - vec3(1.0, 1.0, 0.0));
    float n001 = dot(g001, f - vec3(0.0, 0.0, 1.0));
    float n101 = dot(g101, f - vec3(1.0, 0.0, 1.0));
    float n011 = dot(g011, f - vec3(0.0, 1.0, 1.0));
    float n111 = dot(g111, f - vec3(1.0, 1.0, 1.0));
    
    // Trilinear interpolation
    vec3 u = fade(f);
    
    // Interpolate along x
    float nx00 = mix(n000, n100, u.x);
    float nx10 = mix(n010, n110, u.x);
    float nx01 = mix(n001, n101, u.x);
    float nx11 = mix(n011, n111, u.x);
    
    // Interpolate along y
    float nxy0 = mix(nx00, nx10, u.y);
    float nxy1 = mix(nx01, nx11, u.y);
    
    // Interpolate along z
    return mix(nxy0, nxy1, u.z);
}

// Fractional Brownian Motion (FBM) using Perlin noise
float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // Add multiple octaves of noise
    for(int i = 0; i < 6; i++) {
        value += amplitude * perlin3D(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void main()
{
    // Calculate 3D noise based on world position
    vec3 noisePos = fs_Pos.xyz * 3.0; // Scale the noise for rust pattern detail
    
    // Generate Perlin noise value (no time animation)
    float noiseValue = fbm(noisePos);
    
    // Normalize noise to [0, 1] range
    noiseValue = (noiseValue + 1.0) * 0.5;
    
    // Define base metal color (steel/iron)
    vec3 metalColor = vec3(0.7, 0.7, 0.75); // Light metallic gray
    
    // Define rust colors
    vec3 lightRust = vec3(0.6, 0.3, 0.15);  // Light rust brown
    vec3 darkRust = vec3(0.4, 0.15, 0.08);  // Dark rust brown
    vec3 deepRust = vec3(0.3, 0.1, 0.05);   // Very dark rust
    
    // Create rust intensity based on noise - make rust more sparse
    float rustIntensity = noiseValue;
    
    // Add some variation with different noise scales
    float detailNoise = perlin3D(noisePos * 2.0) * 0.2;
    rustIntensity = clamp(rustIntensity + detailNoise, 0.0, 1.0);
    
    // Make rust much more sparse - only appear in high noise areas
    // Shift the threshold higher so more areas remain metallic
    rustIntensity = smoothstep(0.4, 1.0, rustIntensity);
    
    // Determine rust color based on intensity
    vec3 rustColor;
    if(rustIntensity < 0.2) {
        // Mostly metal with very light rust hints
        rustColor = metalColor;
    } else if(rustIntensity < 0.6) {
        // Light to medium rust areas
        rustColor = mix(metalColor, lightRust, (rustIntensity - 0.2) * 2.5);
    } else {
        // Heavy rust areas (only in very high noise regions)
        rustColor = mix(lightRust, darkRust, (rustIntensity - 0.6) * 2.5);
    }
    
    // Apply Lambert shading with metallic properties
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
    
    // Metallic materials have lower ambient and higher specular-like response
    float ambientTerm = 0.15;
    
    // Enhance the metallic look with stronger contrast
    float metallicResponse = pow(diffuseTerm, 0.8);
    float lightIntensity = metallicResponse + ambientTerm;
    
    // Apply lighting to the rust color
    vec3 shadedColor = rustColor * lightIntensity;
    
    // Blend with base color (less influence from u_Color for more realistic rust)
    vec3 result = mix(shadedColor, u_Color.rgb * lightIntensity, 0.2);
    
    out_Col = vec4(result, u_Color.a);
}