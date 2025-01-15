const CONTRACT_ADDRESS = "YOUR_CONTRACT_ADDRESS_HERE"; // Replace with your contract address
let web3, contract;

// Load contract ABI
fetch('./contractABI.json')
  .then((response) => response.json())
  .then((abi) => {
    initWeb3(abi);
  });

// Initialize Web3 and Contract
async function initWeb3(abi) {
  if (window.ethereum) {
    web3 = new Web3(window.ethereum);
    await window.ethereum.request({ method: 'eth_requestAccounts' });

    const accounts = await web3.eth.getAccounts();
    contract = new web3.eth.Contract(abi, CONTRACT_ADDRESS);

    document.getElementById('listModelForm').addEventListener('submit', (e) => {
      e.preventDefault();
      listModel(accounts[0]);
    });

    loadModels();
  } else {
    alert('Please install MetaMask!');
  }
}

// List a new model
async function listModel(account) {
  const name = document.getElementById('modelName').value;
  const description = document.getElementById('modelDescription').value;
  const price = web3.utils.toWei(document.getElementById('modelPrice').value, 'ether');

  try {
    await contract.methods.listModel(name, description, price).send({ from: account });
    alert('Model listed successfully!');
    loadModels(); // Refresh the model list
  } catch (error) {
    console.error(error);
    alert('Failed to list model.');
  }
}

// Load all models from the contract
async function loadModels() {
  const modelListDiv = document.getElementById('modelList');
  modelListDiv.innerHTML = ''; // Clear existing models

  try {
    const modelCount = await contract.methods.modelCount().call();

    for (let i = 1; i <= modelCount; i++) {
      const model = await contract.methods.getModelDetails(i).call();
      const modelElement = document.createElement('div');
      modelElement.innerHTML = `
        <h3>${model[0]}</h3>
        <p>${model[1]}</p>
        <p>Price: ${web3.utils.fromWei(model[2], 'ether')} ETH</p>
        <button onclick="purchaseModel(${i})">Purchase</button>
      `;
      modelListDiv.appendChild(modelElement);
    }
  } catch (error) {
    console.error(error);
  }
}

// Purchase a model
async function purchaseModel(modelId) {
  try {
    const accounts = await web3.eth.getAccounts();
    const model = await contract.methods.getModelDetails(modelId).call();
    const price = model[2]; // Price in Wei

    await contract.methods.purchaseModel(modelId).send({
      from: accounts[0],
      value: price,
    });
    alert('Model purchased successfully!');
  } catch (error) {
    console.error(error);
    alert('Purchase failed.');
  }
}
