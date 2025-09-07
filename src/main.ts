import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  geometry: 'Cube', // Geometry selection
  tesselations: 5,
  u_Color: [255, 0, 0], // RGB color values (0-255)
  shader: 'Perlin Rust', // Default shader selection
  'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let tessellationController: any; // Reference to tessellation GUI controller
let startTime: number = Date.now(); // 记录开始时间用于动画

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0)); // Center all geometries
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));     // Center all geometries
  cube.create();
}

// Function to get current geometry based on selection
function getCurrentGeometry(): any {
  switch(controls.geometry) {
    case 'Icosphere':
      return icosphere;
    case 'Square':
      return square;
    case 'Cube':
      return cube;
    default:
      return cube;
  }
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  
  // Add geometry selection dropdown
  const geometryController = gui.add(controls, 'geometry', ['Icosphere', 'Cube', 'Square']).name('Geometry');
  
  // Add tessellation control (initially visible)
  tessellationController = gui.add(controls, 'tesselations', 0, 8).step(1).name('Tessellations');
  
  // Function to update tessellation visibility
  function updateTessellationVisibility() {
    if (controls.geometry === 'Icosphere') {
      tessellationController.domElement.style.display = '';
    } else {
      tessellationController.domElement.style.display = 'none';
    }
  }
  
  // Set initial visibility
  updateTessellationVisibility();
  
  // Update visibility when geometry changes
  geometryController.onChange(function(value: string) {
    updateTessellationVisibility();
  });
  
  // Add shader selection dropdown
  gui.add(controls, 'shader', ['Lambert', 'Perlin Rust', 'Wave Deform']).name('Shader Type');
  
  // Add color picker with explicit RGB range validation
  const colorController = gui.addColor(controls, 'u_Color');
  colorController.onChange(function(value: number[]) {
    // Ensure RGB values are clamped to 0-255 range
    controls.u_Color[0] = Math.max(0, Math.min(255, Math.round(value[0])));
    controls.u_Color[1] = Math.max(0, Math.min(255, Math.round(value[1])));
    controls.u_Color[2] = Math.max(0, Math.min(255, Math.round(value[2])));
  });
  
  gui.add(controls, 'Load Scene');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  // Create multiple shader programs
  const lambertShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const perlinShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/perlin-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/perlin-frag.glsl')),
  ]);

  const waveShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/wave-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/wave-frag.glsl')),
  ]);

  // Function to get current shader based on selection
  function getCurrentShader(): ShaderProgram {
    switch(controls.shader) {
      case 'Lambert':
        return lambertShader;
      case 'Perlin Rust':
        return perlinShader;
      case 'Wave Deform':
        return waveShader;
      default:
        return perlinShader;
    }
  }

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    
    // Convert RGB values (0-255) from GUI to OpenGL format (0-1)
    // Clamp values to ensure they're within 0-255 range
    const color = vec4.fromValues(
      Math.max(0, Math.min(255, controls.u_Color[0])) / 255.0,
      Math.max(0, Math.min(255, controls.u_Color[1])) / 255.0, 
      Math.max(0, Math.min(255, controls.u_Color[2])) / 255.0,
      1.0
    );
    
    // Update icosphere if tessellations changed and icosphere is selected
    if(controls.tesselations != prevTesselations && controls.geometry === 'Icosphere')
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    
    // Get the currently selected shader and geometry
    const currentShader = getCurrentShader();
    const currentGeometry = getCurrentGeometry();
    
    // 计算经过的时间（以秒为单位）
    const currentTime = (Date.now() - startTime) / 1000.0;
    
    // 如果使用波浪着色器，设置时间uniform
    if (controls.shader === 'Wave Deform') {
      currentShader.setTime(currentTime);
    }
    
    renderer.render(camera, currentShader, [
      currentGeometry
    ], color);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
