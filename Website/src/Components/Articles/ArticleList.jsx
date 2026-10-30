import React, { useEffect } from 'react'
import { Typography, Carousel } from '@material-tailwind/react';
import { Link, useLocation } from 'react-router-dom';
import { EyeIcon, Pencil, Trash } from 'lucide-react';
import PropTypes from 'prop-types';
const ArticleList = ({ articles, IsLargeScreen, handleDelete }) => {

    const location = useLocation();
    const isAdminLocation = location.pathname.includes('dashboard');
    useEffect(() => {
        if (articles) {
            console.log(articles);
        }
    }, [articles])
    return (
        <>
            {articles.map(article => {
                const formattedDate = new Date(article.createdAt).toLocaleDateString('en-US', {
                    weekday: 'short', // "Mon"
                    year: 'numeric', // "2025"
                    month: 'short', // "Jan"
                    day: 'numeric', // "21"
                });
                
                return (
                    <div className=" bg-white shadow-lg border border-primary-dark p-4 rounded-lg flex flex-col justify-between w-96" key={article._id}>
                        <Carousel className="rounded-xl my-4 bg-gray-400/75 h-max">
                            {article.images?.map((image, index) => (
                                <div key={image.url} className="relative h-40 w-full">
                                    <img
                                        src={image.url}
                                        alt={`Article Image ${index + 1}`}
                                        className="w-full h-full object-cover rounded-xl"
                                    />
                                </div>
                            ))}
                        </Carousel>
                        <Typography variant={IsLargeScreen ? "h3" : "h4"} className="mt-2 text-primary">
                            {article.title}
                        </Typography>
                        <Typography variant="small" className="italic">
                            Published on {formattedDate}
                        </Typography>
                        <Typography variant="paragraph" className='overflow-hidden text-ellipsis line-clamp-2 my-2'>
                            {article.description}
                        </Typography>
                        <div className="flex justify-end items-center gap-4">

                            <Link to={`/article/${article._id}`} className="flex items-center gap-2 text-secondary"><EyeIcon size={30} className="text-secondary btn btn-outline" />{!isAdminLocation && <span className="font-varela font-bold">View</span>}</Link>
                            {isAdminLocation &&
                                (<>
                                    <Link to={`/dashboard/resources/edit/${article._id}`} className=""><Pencil size={30} className="text-secondary" /></Link>
                                    <Trash size={30} className="text-secondary cursor-pointer" onClick={() => handleDelete(article._id)} />
                                </>)}
                        </div>

                    </div>
                )
            })}
        </>
    )
}
ArticleList.propTypes = {
    articles: PropTypes.array.isRequired,
    IsLargeScreen: PropTypes.bool.isRequired,
    handleDelete: PropTypes.func.isRequired
}
export default ArticleList