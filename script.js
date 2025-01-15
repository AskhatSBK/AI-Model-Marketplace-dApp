import Web3 from "web3";

const web3 = new Web3(window.ethereum);
const response = await fetch('./contractABI.json')
const contractAddress = "0xBe2f69569fE8D5870e95f59CDA08bb8910a14341";
const contractABI = await response.json(); // Paste ABI from AIModelMarketplace.json
const contract = new web3.eth.Contract(contractABI,contractAddress);

// Initialize Web3
window.addEventListener("load", async () => {
  if (window.ethereum) {
    web3 = new Web3(window.ethereum);
    await ethereum.request({ method: "eth_requestAccounts" });
    const accounts = await web3.eth.getAccounts();

    contract = new web3.eth.Contract(contractABI, contractAddress);

    document.getElementById("listModelForm").addEventListener("submit", listModel);
    document.getElementById("rateModelForm").addEventListener("submit", rateModel);
    document.getElementById("getModelForm").addEventListener("submit", getModelDetails);
    document.getElementById("withdrawFunds").addEventListener("click", withdrawFunds);

    loadModels();
  } else {
    alert("Please install MetaMask to use this application.");
  }
});

// List a new model
async function listModel(event) {
  event.preventDefault();

  const name = document.getElementById("name").value;
  const description = document.getElementById("description").value;
  const price = document.getElementById("price").value;

  const accounts = await web3.eth.getAccounts();
  await contract.methods.listModel(name, description, price).send({ from: accounts[0] });
  alert("Model listed successfully!");
  loadModels();
}

// Load models
async function loadModels() {
  const modelList = document.getElementById("modelList");
  modelList.innerHTML = "";

  const modelCount = await contract.methods.modelCount().call();
  for (let i = 0; i < modelCount; i++) {
    const model = await contract.methods.models(i).call();
    modelList.innerHTML += `
      <div>
        <h3>${model.name}</h3>
        <p>${model.description}</p>
        <p>Price: ${model.price} wei</p>
        <p>Creator: ${model.creator}</p>
        <p>Rating: ${model.ratingCount > 0 ? (model.totalRating / model.ratingCount).toFixed(2) : "Not rated yet"}</p>
        <button onclick="purchaseModel(${i})">Purchase</button>
      </div>
    `;
  }
}

// Purchase a model
async function purchaseModel(modelId) {
  const accounts = await web3.eth.getAccounts();
  const model = await contract.methods.models(modelId).call();

  await contract.methods.purchaseModel(modelId).send({ from: accounts[0], value: model.price });
  alert("Model purchased successfully!");
}

// Rate a model
async function rateModel(event) {
  event.preventDefault();

  const modelId = document.getElementById("rateModelId").value;
  const rating = document.getElementById("rating").value;

  const accounts = await web3.eth.getAccounts();
  await contract.methods.rateModel(modelId, rating).send({ from: accounts[0] });
  alert("Model rated successfully!");
}

// Get model details
async function getModelDetails(event) {
  event.preventDefault();

  const modelId = document.getElementById("detailModelId").value;
  const model = await contract.methods.getModelDetails(modelId).call();

  document.getElementById("modelDetails").innerHTML = `
    <h3>${model.name}</h3>
    <p>${model.description}</p>
    <p>Price: ${model.price} wei</p>
    <p>Creator: ${model.creator}</p>
    <p>Rating: ${model.ratingCount > 0 ? (model.totalRating / model.ratingCount).toFixed(2) : "Not rated yet"}</p>
  `;
}

// Withdraw funds
async function withdrawFunds() {
  const accounts = await web3.eth.getAccounts();
  await contract.methods.withdrawFunds().send({ from: accounts[0] });
  alert("Funds withdrawn successfully!");
}
