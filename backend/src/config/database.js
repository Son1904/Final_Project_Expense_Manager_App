const mongoose = require('mongoose');
const { Pool } = require('pg');
const logger = require('../utils/logger');

// PostgreSQL connection pool
let pgPool = null;

/**
 * Connect to MongoDB using Mongoose
 */
const connectMongoDB = async () => {
  try {
    const options = {
      maxPoolSize: parseInt(process.env.MONGODB_POOL_SIZE) || 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    };

    await mongoose.connect(process.env.MONGODB_URI, options);
    
    logger.info('MongoDB connected successfully');
    logger.info(`Database: ${mongoose.connection.name}`);

    // Handle MongoDB connection events
    mongoose.connection.on('error', (err) => {
      logger.error('MongoDB connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB disconnected');
    });

    mongoose.connection.on('reconnected', () => {
      logger.info('MongoDB reconnected');
    });

  } catch (error) {
    logger.error('MongoDB connection failed:', error);
    throw error;
  }
};

/**
 * Connect to PostgreSQL using connection pool
 */
const connectPostgreSQL = async () => {
  try {
    pgPool = new Pool({
      host: process.env.POSTGRES_HOST,
      port: parseInt(process.env.POSTGRES_PORT),
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DB,
      max: parseInt(process.env.POSTGRES_POOL_SIZE) || 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Test connection
    const client = await pgPool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();

    logger.info('PostgreSQL connected successfully');
    logger.info(`Database: ${process.env.POSTGRES_DB}`);
    logger.info(`Server time: ${result.rows[0].now}`);

    // Handle pool errors
    pgPool.on('error', (err, client) => {
      logger.error('Unexpected PostgreSQL pool error:', err);
    });

  } catch (error) {
    logger.error('PostgreSQL connection failed:', error);
    throw error;
  }
};

/**
 * Get PostgreSQL pool instance
 */
const getPgPool = () => {
  if (!pgPool) {
    throw new Error('PostgreSQL pool not initialized. Call connectPostgreSQL first.');
  }
  return pgPool;
};

/**
 * Close PostgreSQL connection pool
 */
const closePgPool = async () => {
  if (pgPool) {
    await pgPool.end();
    logger.info('PostgreSQL pool has been closed');
  }
};

/**
 * Execute PostgreSQL query with error handling
 */
const executeQuery = async (query, params = []) => {
  const client = await pgPool.connect();
  try {
    const result = await client.query(query, params);
    return result;
  } catch (error) {
    logger.error('Query execution error:', error);
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  connectMongoDB,
  connectPostgreSQL,
  getPgPool,
  closePgPool,
  executeQuery,
};
