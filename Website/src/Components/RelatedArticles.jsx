import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom';
import {
    Card,
    Typography,
    Button,
} from "@material-tailwind/react";
import PropTypes from 'prop-types';
const RelatedArticles = ({ articles }) => {
    const [IsLargeScreen, setIsLargeScreen] = useState(false);
    useEffect(() => {
        const handleResize = () => {
            setIsLargeScreen(window.innerWidth >= 768); // Tailwind's md breakpoint is 768px
        };

        // Set initial screen size and add event listener
        handleResize();
        window.addEventListener("resize", handleResize);

        return () => window.removeEventListener("resize", handleResize);
    }, [])
    return (
        <Card className="h-[calc(100vh-2rem)] w-full p-4 " color="transparent">
            <Typography variant="h2" className="text-primary mb-4">Other Articles</Typography>
            <div className="overflow-y-auto gap-2 flex flex-col items-center">
                {articles.map((article) => {
                    const formattedDate = new Date(article.createdAt).toLocaleDateString('en-US', {
                        weekday: 'short', // "Mon"
                        year: 'numeric', // "2025"
                        month: 'short', // "Jan"
                        day: 'numeric', // "21"
                    });
                    return (
                        <div key={article._id} className="max-h-96 w-72 bg-white shadow-lg border border-primary-dark p-4 rounded-lg flex flex-col">
                            <img src={article.images[0].url} alt="" className="object-cover h-40" />
                            <Typography variant={IsLargeScreen ? "h3" : "h4"} className="mt-2 text-primary">
                                {article.title}
                            </Typography>
                            <Typography variant="small" className="italic">
                                Published on {formattedDate}
                            </Typography>
                            <Typography variant="paragraph" className='overflow-hidden text-ellipsis line-clamp-2 my-2'>
                               {article.description}
                            </Typography>
                            <Link to={`/article/${article._id}`} className="w-full"><Button className="bg-secondary w-full">See more</Button></Link>
                        </div>
                    )
                })}


            </div>
        </Card>
    )
}
RelatedArticles.propTypes = {
    articles: PropTypes.array.isRequired
}
export default RelatedArticles