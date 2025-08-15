const express = require('express');
const app = express();

// Test routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.get('/api/test', (req, res) => {
  res.json({ message: 'Test route works' });
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`Test server running on port ${PORT}`);
}); 