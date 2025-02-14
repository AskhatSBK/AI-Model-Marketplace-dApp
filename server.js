
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 50 * 1024 * 1024 },
});

app.get('/api/config', (req, res) => {
  res.json({
      tokenAddress: process.env.TOKEN_ADDRESS,
      tokenABI: JSON.parse(process.env.TOKEN_ABI),
  });
});

let models = [];
let nextId = 1; // ID to uniquely identify models


app.get('/api/getModels', (req, res) => {
  res.json(models);
});

app.post('/api/createModel', upload.single('file'), (req, res) => {
  const { name, description, price, seller } = req.body;
  const file = req.file;

  if (!name || !description || !price || !file || !seller) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const newModel = {
    id: nextId++,
    name,
    description,
    price,
    seller,
    filePath: path.join(__dirname, 'uploads', file.filename),
    status: 'available',
  };

  models.push(newModel);
  res.status(201).json(newModel);
});

app.post('/api/markAsSold', (req, res) => {
  const { modelId } = req.body;
  console.log('Received modelId:', modelId); // Log the received modelId

  // Make sure modelId is passed as a string or number correctly
  const model = models.find(m => m.id == modelId);  // Use `==` to allow type coercion (string or number)

  if (!model) {
    console.error('Model not found:', modelId); // Log if model is not found
    return res.status(404).json({ error: 'Model not found' });
  }

  model.status = 'sold';  // Mark the model as sold
  console.log('Updated model:', model);  // Log the updated model
  res.status(200).json({ success: true, model });
});


app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});