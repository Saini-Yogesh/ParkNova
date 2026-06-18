require('dotenv').config();
const http = require('http');
const app = require('./app');
const logger = require('./utils/logger');

const PORT = process.env.PORT || 5000;

// Export the Express app for Vercel Serverless Functions
module.exports = app;

// Start server locally ONLY if not running in Vercel
if (!process.env.VERCEL) {
  const server = http.createServer(app);
  
  // Note: WebSockets (socket.io) have been disabled because Vercel Serverless
  // does not support persistent WebSocket connections.
  
  server.listen(PORT, () => {
    logger.info(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (err, promise) => {
    logger.error(`Error: ${err.message}`);
    server.close(() => process.exit(1));
  });
}
