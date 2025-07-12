import React from 'react';
import ReactFlow from 'reactflow';
import 'reactflow/dist/style.css';

const nodes = [
  {
    id: '1',
    position: { x: 0, y: 0 },
    data: { label: 'Node 1' },
    type: 'default',
  },
  {
    id: '2',
    position: { x: 100, y: 100 },
    data: { label: 'Node 2' },
    type: 'default',
  },
];

const edges = [
  { id: 'e1-2', source: '1', target: '2', type: 'default' },
];

function App() {
  return (
    <div style={{ width: '100vw', height: '100vh' }}>
      <ReactFlow nodes={nodes} edges={edges} />
    </div>
  );
}

export default App;