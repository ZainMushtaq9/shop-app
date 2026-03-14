const { Client } = require('pg');
const fs = require('fs');

async function runSQL() {
  const client = new Client({
    connectionString: "postgres://postgres:iM1faqxzH6sA-JhvweKHWDNqDxLqvsDaHpaFRi1LdEM@db.wzypjlnexfmkghwmhyrf.supabase.co:5432/postgres"
  });

  try {
    await client.connect();
    console.log("Connected to Supabase PostgreSQL (Direct).");
    const sql = fs.readFileSync('supabase_schema_fix.sql', 'utf8');
    
    await client.query(sql);
    console.log("SQL executed successfully.");
    
  } catch (err) {
    console.error("Error executing SQL:", err);
  } finally {
    await client.end();
  }
}

runSQL();
