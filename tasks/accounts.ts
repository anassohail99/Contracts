import { formatEther, parseEther } from "ethers/lib/utils";
import { task } from "hardhat/config";

import { deployContract } from "./utils";

task("deploy-timelock", "Deploy TimeLock Contract").setAction(async (cliArgs, { ethers, run, network }) => {
  await run("compile");

  const signer = (await ethers.getSigners())[0];
  console.log("Signer");
  console.log("  at", signer.address);
  console.log("  ETH", formatEther(await signer.getBalance()));

  console.log("Network");
  console.log("   ", network.name);

  const TimeLockContract = await deployContract("TimeLock", await ethers.getContractFactory("TimeLock"), signer);

  await TimeLockContract.deployTransaction.wait(5);
  delay(60000);

  await run("verify:verify", {
    address: TimeLockContract.address,
    // constructorArguments: signer.address,
  });
});

task("deploy-testTimelock", "Deploy TimeLock Contract")
  .addParam("timelock", "timelock address")
  .setAction(async (cliArgs, { ethers, run, network }) => {
    await run("compile");

    const signer = (await ethers.getSigners())[0];
    console.log("Signer");
    console.log("  at", signer.address);
    console.log("  ETH", formatEther(await signer.getBalance()));

    console.log("Network");
    console.log("   ", network.name);

    const args = {
      timelock: cliArgs.timelock,
    };

    console.log("Task Args");
    console.log(args);

    const TimeLockTestContract = await deployContract(
      "TestTimeLock",
      await ethers.getContractFactory("TestTimeLock"),
      signer,
      [args.timelock],
    );

    await TimeLockTestContract.deployTransaction.wait(5);
    delay(10000);

    await run("verify:verify", {
      address: TimeLockTestContract.address,
      constructorArguments: [args.timelock],
    });
  });

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
