const { Pool } = require('pg');
require('dotenv').config();

async function dropCassoTable() {
  const pool = new Pool({
    host: process.env.POSTGRES_HOST,
    port: process.env.POSTGRES_PORT,
    database: process.env.POSTGRES_DB,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
  });

  try {
    console.log('Connecting to PostgreSQL...');
    
    // Drop casso_webhooks table
    await pool.query('DROP TABLE IF EXISTS casso_webhooks CASCADE;');
    console.log('✓ Dropped casso_webhooks table');

    console.log('\n✅ Cleanup completed successfully');
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await pool.end();
    process.exit(1);
  }
}

dropCassoTable();
