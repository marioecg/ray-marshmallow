const canvasSketch = require('canvas-sketch');
const createShader = require('canvas-sketch-util/shader');
const frag = require('./shaders/main.glsl');

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
const sketch = ({ gl, canvas, width, height }) => {
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

  return createShader({
    gl,
    frag,
    uniforms: {
      uTime: ({ time }) => time,
      uResolution: () => [width, height],
      uMouse: () => [mouse.x, mouse.y],
    }
  });
};

canvasSketch(sketch, settings);

/**
 * More events
 */