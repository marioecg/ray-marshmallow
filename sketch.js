const canvasSketch = require('canvas-sketch');
const createShader = require('canvas-sketch-util/shader');
const frag = require('./shaders/main.glsl');
const loadAsset = require('load-asset');
const createRegl = require('regl');

/**
 * Settings
 */
const settings = {
  context: 'webgl',
  animate: true,
  dimensions: [1000, 1000]
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

  const px = await loadAsset('/assets/px.png');
  const nx = await loadAsset('/assets/nx.png');
  const py = await loadAsset('/assets/py.png');
  const ny = await loadAsset('/assets/ny.png');
  const pz = await loadAsset('/assets/pz.png');
  const nz = await loadAsset('/assets/nz.png');

  // Setup REGL with canvas context
  const regl = createRegl({ gl });

  const cubemap = regl.cube(px, nx, py, ny, pz, nz);

  return createShader({
    gl,
    frag,
    uniforms: {
      uTime: ({ time }) => time,
      uResolution: () => [width, height],
      uMouse: () => [mouse.x, mouse.y],
      tCubemap: cubemap,
    }
  });
};

canvasSketch(sketch, settings);

/**
 * More events
 */