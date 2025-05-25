const setupSchema = require('./schema'); // ensure you have a schema.js

module.exports = function (db) {
  setupSchema(db); // This calls your schema definition
};
