import React, { useState, useEffect } from 'react'
import StickyNavbar from '../Components/Navbar'
import { Typography, Carousel } from '@material-tailwind/react'
import { useParams } from 'react-router-dom'
import { useDispatch, useSelector } from 'react-redux';
import { getArticleDetails, getArticles } from '../redux/actions/articleActions'
import ArticleList from '../Components/Articles/ArticleList'
import { createPortal } from 'react-dom';
const SingleArticle = () => {
    const dispatch = useDispatch();
    const { articles, articleDetails } = useSelector((state) => state.articles);
    const { id } = useParams();
    const [IsLargeScreen, setIsLargeScreen] = useState(false);
    const [combinedHTML, setCombinedHTML] = useState('');
    const [carouselContainer, setCarouselContainer] = useState(null);
    const formattedDate = new Date(articleDetails.createdAt).toLocaleDateString('en-US', {
        weekday: 'short', // "Mon"
        year: 'numeric', // "2025"
        month: 'short', // "Jan"
        day: 'numeric', // "21"
    });

    useEffect(() => {
        dispatch(getArticleDetails(id));
        dispatch(getArticles());
    }, [dispatch, id]);

    useEffect(() => {
        if (articleDetails) {
            const carouselPlaceholder = '<div id="carousel-placeholder"></div>';
            const extraHTML = `<small class="font-parkinsans text-primary italic">Published on ${formattedDate}</small>`;
            setCombinedHTML(carouselPlaceholder + articleDetails.content + extraHTML);
        }
    }, [articleDetails])
    useEffect(() => {
        const el = document.getElementById('carousel-placeholder');
        if (el) setCarouselContainer(el);
    }, [combinedHTML]);
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
        <>
            <StickyNavbar />
            <section
                className="p-4 bg-lightbg flex flex-col lg:flex-row justify-between"
            >
                <div className="w-full">
                    <div className="article-content" dangerouslySetInnerHTML={{ __html: combinedHTML }} />
                    {carouselContainer &&
                        createPortal(
                            <>
                                <Typography variant="h2" className="text-center font-parkinsans">{articleDetails?.title}</Typography>
                                <Carousel className="rounded-xl my-4 bg-gray-400/75">
                                    {articleDetails.images?.map((image, index) => (
                                        <div key={image.url} className="relative h-[calc(50vh-3rem)] w-full">
                                            <img
                                                src={image.url}
                                                alt={`Article Image ${index + 1}`}
                                                className="w-full h-full object-cover rounded-xl"
                                            />
                                        </div>
                                    ))}
                                </Carousel>
                            </>,
                            carouselContainer
                        )}

                </div>
                <div className="h-full">

                    <Typography variant="h2" className="text-center font-parkinsans">Other Articles</Typography>
                    <div className="flex flex-col gap-4 h-full overflow-y-auto">
                        <ArticleList articles={articles} isLargeScreen={IsLargeScreen} />
                    </div>
                </div>

            </section>


        </>
    )
}

export default SingleArticle