module.exports = function softDeletePlugin(schema, options = {}) {
  // Soft delete fields
  schema.add({
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  });

  // query middleware (auto exclude deleted documents)
  schema.pre(/^find/, function () {
    const queryOptions = this.getOptions();
    const filter = this.getFilter();

    // Allow authorized queries to bypass the filter
    if (queryOptions.skipDeletedFilter) {
      return;
    }

    // Include deleted documents when requested
    if (filter.includeDeleted === true) {
      delete filter.includeDeleted;
      this.setQuery(filter);
      return;
    }

    // Apply default filter
    if (filter.isDeleted === undefined) {
      this.where({ isDeleted: false });
    }
  });

  // soft delete single document
  schema.statics.softDeleteById = function (id) {
    return this.findOneAndUpdate(
      { _id: id, isDeleted: false },
      {
        $set: {
          isDeleted: true,
          deletedAt: new Date(),
        },
      },
      {
        new: true,
        runValidators: true,
      }
    );
  };

  // restore single document
  schema.statics.restoreById = function (id) {
    return this.findOneAndUpdate(
      { _id: id, isDeleted: true },
      {
        $set: {
          isDeleted: false,
          deletedAt: null,
        },
      },
      {
        new: true,
        runValidators: true,
        skipDeletedFilter: true,
      }
    );
  };

  // soft delete multiple document
  schema.statics.softDeleteMany = function (filter = {}) {
    return this.updateMany(
      {
        ...filter,
        isDeleted: false,
      },
      {
        $set: {
          isDeleted: true,
          deletedAt: new Date(),
        },
      },
      {
        runValidators: true,
      }
    );
  };

  // restore multiple documents
  schema.statics.restoreMany = function (filter = {}) {
    return this.updateMany(
      {
        ...filter,
        isDeleted: true,
      },
      {
        $set: {
          isDeleted: false,
          deletedAt: null,
        },
      },
      {
        runValidators: true,
      }
    );
  };

  // retrieve documents

  // Find all documents, including deleted ones
  schema.statics.findIncludingDeleted = function (filter = {}) {
    return this.find(filter).setOptions({
      skipDeletedFilter: true,
    });
  };

  // Find only soft-deleted documents
  schema.statics.findOnlyDeleted = function (filter = {}) {
    return this.find({
      ...filter,
      isDeleted: true,
    }).setOptions({
      skipDeletedFilter: true,
    });
  };

  // Find active documents only
  schema.statics.findActive = function (filter = {}) {
    return this.find({
      ...filter,
      isDeleted: false,
    });
  };
};
