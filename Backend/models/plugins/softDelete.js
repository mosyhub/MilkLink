// softDelete.js
module.exports = function softDeletePlugin(schema, options = {}) {
  schema.add({
    isDeleted: { type: Boolean, default: false },
    deletedAt: { type: Date, default: null },
  });

  schema.pre(/^find/, function (next) {
    if (this.getOptions().skipDeletedFilter) {
      return next(); // Don't apply any filter
    }

    if (!this.getFilter().includeDeleted) {
      this.where({ isDeleted: false });
    } else {
      this.setQuery({ ...this.getFilter(), includeDeleted: undefined });
    }

    next();
  });


  // --- Static Methods ---

  // Soft delete a single document
  schema.statics.softDeleteById = async function (id) {
    return this.findByIdAndUpdate(id, {
      isDeleted: true,
      deletedAt: new Date(),
    });
  };

  schema.statics.restoreById = async function (id) {
    return this.findOneAndUpdate(
      { _id: id, isDeleted: true }, // Find only soft-deleted
      { isDeleted: false, deletedAt: null },
      { new: true } // Return the updated document
    ).setOptions({ skipDeletedFilter: true }); // ✅ Bypass soft-delete filter
  };


  // Soft delete multiple documents
  schema.statics.softDeleteMany = async function (filter = {}) {
    return this.updateMany(filter, {
      isDeleted: true,
      deletedAt: new Date(),
    });
  };

  // Restore multiple documents
  schema.statics.restoreMany = async function (filter = {}) {
    return this.updateMany(filter, {
      isDeleted: false,
      deletedAt: null,
    });
  };

  // Find documents including soft-deleted ones
  schema.statics.findIncludingDeleted = function (filter = {}) {
    return this.find({ ...filter, includeDeleted: true });
  };
  schema.statics.findOnlyDeleted = function (filter = {}) {
    return this.find({ ...filter, isDeleted: true }).setOptions({ skipDeletedFilter: true });
  };
};
