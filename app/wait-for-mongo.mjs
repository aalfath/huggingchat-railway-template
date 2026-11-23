// Waits until MongoDB accepts writes (replica set initiated), up to WAIT_FOR_MONGO_SECONDS.
import { MongoClient } from "mongodb";

const url = process.env.MONGODB_URL;
const limit = Number(process.env.WAIT_FOR_MONGO_SECONDS || 240) * 1000;
const started = Date.now();
let last = "";
while (Date.now() - started < limit) {
	const client = new MongoClient(url, {
		directConnection: process.env.MONGODB_DIRECT_CONNECTION === "true",
		serverSelectionTimeoutMS: 3000,
		connectTimeoutMS: 3000,
	});
	try {
		await client.connect();
		const hello = await client.db("admin").command({ hello: 1 });
		if (hello.isWritablePrimary) {
			console.log(`[railway] MongoDB is ready after ${Math.round((Date.now() - started) / 1000)} s`);
			await client.close();
			process.exit(0);
		}
		last = "MongoDB is up but not primary yet";
	} catch (e) {
		last = e.message;
	}
	await client.close().catch(() => {});
	await new Promise((r) => setTimeout(r, 2000));
}
console.error(`[railway] MongoDB not ready after ${limit / 1000} s: ${last}`);
process.exit(1);
