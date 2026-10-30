import React from 'react'
import PropTypes from 'prop-types'


const Loader = ({ size }) => {
    let loaderSize = "w-10 h-10";
    if (size === "small") {
        loaderSize = "w-6 h-6";
    }
    else if (size === "large") {
        loaderSize = "w-16 h-16";
    }
    return (
        <div className={`${loaderSize} border-4 border-t-secondary border-gray-300 rounded-full animate-spin`}></div>
    )
}
Loader.propTypes = {
    size: PropTypes.string,
}
export default Loader