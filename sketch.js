const canvasSketch = require('canvas-sketch');
const createShader = require('canvas-sketch-util/shader');
const createRegl = require('regl');
const loadAsset = require('load-asset');
const frag = require('./shaders/main.glsl');

/**
 * Settings
 */
const settings = {
  context: 'webgl',
  animate: true,
  dimensions: [1500, 1500],
  duration: 20,
  fps: 60,
};

const mouse = {
  x: 0,
  y: 0
};

let mouseIsDown = false;

/**
 * Main sketch function
 */
const sketch = async ({ gl, canvas, width, height }) => {
  // Update mouse only when it's down
  canvas.onmousedown = () => mouseIsDown = true;

  canvas.onmouseup = () => mouseIsDown = false;

  canvas.onmousemove = e => {
    if (!mouseIsDown) return;

    const { clientX, clientY } = e;

    mouse.x = clientX;
    mouse.y = clientY;
  }

  // Load cubemap textures
  const textures = await Promise.all([    
    loadAsset('./assets/02/px.png'),
    loadAsset('./assets/02/nx.png'),
    loadAsset('./assets/02/py.png'),
    loadAsset('./assets/02/ny.png'),
    loadAsset('./assets/02/pz.png'),
    loadAsset('./assets/02/nz.png')
  ])

  // Setup REGL with canvas context
  const regl = createRegl({ gl });

  // Create cubemap
  const cubemap = regl.cube(...textures);
  
  // Shader object
  return createShader({
    gl,
    frag,
    uniforms: {
      uTime: ({ time, playhead }) => playhead * Math.PI * 2.0,
      uResolution: () => [width, height],
      uMouse: () => [mouse.x, mouse.y],
      tCube: () => cubemap,
    }
  });
};

canvasSketch(sketch, settings);