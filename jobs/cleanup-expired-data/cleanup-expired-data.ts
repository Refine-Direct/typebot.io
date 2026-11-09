import { resolve } from "node:path";
import { config } from "dotenv";

const main = async () => {
  const environment = config({ path: resolve(__dirname, "../../.env") });
  if (environment.error) {
    console.error("[cleanup] Unable to load the repository root .env file.");
    process.exitCode = 1;
    return;
  }
  if (!process.env.DATABASE_URL) {
    console.error("[cleanup] DATABASE_URL is not set.");
    process.exitCode = 1;
    return;
  }
  if (!process.env.DATABASE_URL_REPLICA) {
    process.env.DATABASE_URL_REPLICA = process.env.DATABASE_URL;
    console.log("[cleanup] Using the primary database for replica reads.");
  }

  // Only database configuration is needed by this maintenance entry point.
  process.env.SKIP_ENV_CHECK = "true";

  if (process.argv.includes("--check")) {
    console.log(
      "[cleanup] Environment check passed. No database connection or deletion was performed.",
    );
    return;
  }

  // Prisma checks the environment at import time, so load it after dotenv.
  const { default: prisma } = await import(
    "../../packages/prisma/src/withReadReplica"
  );
  try {
    const { cleanExpiredData } = await import(
      "../../packages/scripts/src/helpers/cleanExpiredData"
    );
    console.log("[cleanup] Starting expired data cleanup.");
    console.log("[cleanup] Completed:", await cleanExpiredData());
  } finally {
    await prisma.$disconnect();
  }
};

main().catch(() => {
  // Database errors may contain connection details; keep credentials out of logs.
  console.error(
    "[cleanup] Failed. Check the database configuration, connectivity and server logs. Cleanup may have partially completed.",
  );
  process.exitCode = 1;
});
