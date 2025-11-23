require('dotenv').config();
const app = require('./src/app');
const { connectMongoDB, connectPostgreSQL } = require('./src/config/database');
const logger = require('./src/utils/logger');

const PORT = process.env.PORT || 3000;

let server;

/**
 * Start server after successful database connections
 */
const startServer = async () => {
  try {
    // Connect to databases
    await connectMongoDB();
    await connectPostgreSQL();

    // Start Express server
    server = app.listen(PORT, () => {
      logger.info(`Server is running on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV}`);
      logger.info(`Health check: http://localhost:${PORT}/api/health`);
    });

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

/**
 * Graceful shutdown handler
 */
const gracefulShutdown = (signal) => {
  logger.info(`\n${signal} received. Starting graceful shutdown...`);
  
  if (server) {
    server.close(() => {
      logger.info('HTTP server closed');
      
      // Close database connections
      const mongoose = require('mongoose');
      mongoose.connection.close(false, () => {
        logger.info('MongoDB connection closed');
      });

      // Close PostgreSQL connection pool
      const { closePgPool } = require('./src/config/database');
      closePgPool()
        .then(() => {
          logger.info('PostgreSQL pool closed');
          process.exit(0);
        })
        .catch((err) => {
          logger.error('Error closing PostgreSQL pool:', err);
          process.exit(1);
        });
    });

    // Force shutdown after 10 seconds
    setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, 10000);
  } else {
    process.exit(0);
  }
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('UNHANDLED_REJECTION');
});

// Start the server
startServer();
