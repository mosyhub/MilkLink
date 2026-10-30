import React from 'react'

const HorizontalLoader = () => {
    return (

        <div className="w-full gap-x-2 flex items-center mb-8">
            <div className="w-2 bg-[#d07697] animate-bounce h-2 rounded-full"></div>
            <div className="w-2 animate-bounce h-2 bg-[#dc5385] rounded-full"></div>
            <div className="w-2 h-2 animate-bounce bg-[#E53777] rounded-full"></div>
        </div>

    )
}

export default HorizontalLoader