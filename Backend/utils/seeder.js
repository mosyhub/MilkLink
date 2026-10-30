const Coffee = require('../models/coffee');
const dotenv = require('dotenv');
const connectDatabase = require('../config/database');

const coffees = require('../data/coffees');

//Setting dotenv file
dotenv.config({ path: 'config/.env'});

connectDatabase();

const seedCoffees = async () => {
    try {

        await Coffee.deleteMany();
        console.log('All Coffees Deleted');

        await Coffee.insertMany(coffees);
        console.log('All Coffees Created');

        process.exit();

    } catch (error){
        console.log(error.message);
        process.exit();
    }
}


seedCoffees();