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
  dimensions: [1500, 1500]
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
  /**
   * Update mouse only when mouse is down
   */
  canvas.onmousedown = () => mouseIsDown = true;

  canvas.onmouseup = () => mouseIsDown = false;

  canvas.onmousemove = e => {
    if (!mouseIsDown) return;

    const { clientX, clientY } = e;

    mouse.x = clientX;
    mouse.y = clientY;
  }

  /**
   * Load cubemap textures
   */
   const textures = await Promise.all([    
    loadAsset('./assets/px.png'),
    loadAsset('./assets/nx.png'),
    loadAsset('./assets/py.png'),
    loadAsset('./assets/ny.png'),
    loadAsset('./assets/pz.png'),
    loadAsset('./assets/nz.png')
  ])

  // Setup REGL with canvas context
  const regl = createRegl({ gl });

  const cubemap = regl.cube(...textures);

  return createShader({
    gl,
    frag,
    uniforms: {
      uTime: ({ time }) => time,
      uResolution: () => [width, height],
      uMouse: () => [mouse.x, mouse.y],
      tCube: () => cubemap,
    }
  });
};

canvasSketch(sketch, settings);