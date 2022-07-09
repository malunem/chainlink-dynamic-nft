const hre = require("hardhat"); 
  
 async function main() { 
   const BullBear = await hre.ethers.getContractFactory("BullBear"); 
   const BullBear = await BullBear.deploy(); 
   await BullBear.deployed(); 
  
   console.log("BullBear deployed to: ", BullBear.address); 
 } 
  
 main() 
   .then(() => process.exit(0)) 
   .catch((error) => { 
     console.error(error); 
     process.exit(1); 
   })
