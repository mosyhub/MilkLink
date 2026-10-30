import React, { useState, useEffect } from 'react'
import { Typography, Button, Input } from '@material-tailwind/react'
import StickyNavbar from '../Components/Navbar'
import { useDispatch, useSelector } from 'react-redux';
import { getArticles } from '../redux/actions/articleActions';
import ArticleList from '../Components/Articles/ArticleList';
const Article = () => {
    const [IsLargeScreen, setIsLargeScreen] = useState(false);
    const dispatch = useDispatch();
    const { articles } = useSelector((state) => state.articles);
    const [search, setSearch] = useState('')
    useEffect(() => {
        const handleResize = () => {
            setIsLargeScreen(window.innerWidth >= 768); // Tailwind's md breakpoint is 768px
        };

        // Set initial screen size and add event listener
        handleResize();
        window.addEventListener("resize", handleResize);

        return () => window.removeEventListener("resize", handleResize);
    }, [])
    useEffect(() => {
        dispatch(getArticles(search));
    }, [dispatch, search])

    useEffect(() => {
        if (articles) {
            console.log(articles);
        }
    }, [articles])
    const handleSearch = () => {
        dispatch(getArticles(search));
    }
    return (
        <>
            <StickyNavbar />
            <section style={{
                backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svgjs='http://svgjs.dev/svgjs' width='1440' height='560' preserveAspectRatio='none' viewBox='0 0 1440 560'%3e%3cg mask='url(%26quot%3b%23SvgjsMask1053%26quot%3b)' fill='none'%3e%3crect width='1440' height='560' x='0' y='0' fill='rgba(245%2c 245%2c 220%2c 1)'%3e%3c/rect%3e%3ccircle r='46.666666666666664' cx='1201.26' cy='244.82' stroke='rgba(255%2c 85%2c 128%2c 1)' stroke-width='1.9' stroke-dasharray='2%2c 2'%3e%3c/circle%3e%3crect width='103' height='103' clip-path='url(%26quot%3b%23SvgjsClipPath1054%26quot%3b)' x='413.44' y='-14.07' fill='url(%26quot%3b%23SvgjsPattern1055%26quot%3b)' transform='rotate(63.96%2c 464.94%2c 37.43)'%3e%3c/rect%3e%3crect width='360' height='360' clip-path='url(%26quot%3b%23SvgjsClipPath1056%26quot%3b)' x='1238.91' y='192.58' fill='url(%26quot%3b%23SvgjsPattern1057%26quot%3b)' transform='rotate(302.42%2c 1418.91%2c 372.58)'%3e%3c/rect%3e%3crect width='300.52' height='300.52' clip-path='url(%26quot%3b%23SvgjsClipPath1058%26quot%3b)' x='1165.93' y='373.27' fill='url(%26quot%3b%23SvgjsPattern1059%26quot%3b)' transform='rotate(88.38%2c 1316.19%2c 523.53)'%3e%3c/rect%3e%3crect width='372' height='372' clip-path='url(%26quot%3b%23SvgjsClipPath1060%26quot%3b)' x='294.72' y='-69.9' fill='url(%26quot%3b%23SvgjsPattern1061%26quot%3b)' transform='rotate(126.82%2c 480.72%2c 116.1)'%3e%3c/rect%3e%3cpath d='M1045.5 107.67a5.6 5.6 0 1 0 11.19-0.63 5.6 5.6 0 1 0-11.19 0.63zM1061.48 106.77a5.6 5.6 0 1 0 11.18-0.63 5.6 5.6 0 1 0-11.18 0.63zM1077.45 105.87a5.6 5.6 0 1 0 11.19-0.64 5.6 5.6 0 1 0-11.19 0.64zM1093.43 104.96a5.6 5.6 0 1 0 11.18-0.63 5.6 5.6 0 1 0-11.18 0.63z' fill='rgba(255%2c 85%2c 128%2c 1)'%3e%3c/path%3e%3cpath d='M954.53 377.9 L982.63 235.36L1056.457654981135 394.5076549811351z' stroke='rgba(255%2c 85%2c 128%2c 1)' stroke-width='1.22' stroke-dasharray='3%2c 3'%3e%3c/path%3e%3cpath d='M342.6 348L330.33 344.34 331.22 331.56 318.95 327.89 319.83 315.12 307.56 311.45 308.45 298.67M349.18 343.45L336.91 339.78 337.8 327.01 325.53 323.34 326.41 310.56 314.14 306.9 315.02 294.12M355.76 338.89L343.49 335.23 344.37 322.45 332.1 318.78 332.99 306.01 320.72 302.34 321.6 289.57' stroke='rgba(255%2c 85%2c 128%2c 1)' stroke-width='2.35' stroke-dasharray='3%2c 2'%3e%3c/path%3e%3crect width='221.2' height='221.2' clip-path='url(%26quot%3b%23SvgjsClipPath1062%26quot%3b)' x='557.76' y='46.64' fill='url(%26quot%3b%23SvgjsPattern1063%26quot%3b)' transform='rotate(257.18%2c 668.36%2c 157.24)'%3e%3c/rect%3e%3crect width='324' height='324' clip-path='url(%26quot%3b%23SvgjsClipPath1064%26quot%3b)' x='659.01' y='-100.44' fill='url(%26quot%3b%23SvgjsPattern1065%26quot%3b)' transform='rotate(14.45%2c 821.01%2c 61.56)'%3e%3c/rect%3e%3crect width='313.56' height='313.56' clip-path='url(%26quot%3b%23SvgjsClipPath1066%26quot%3b)' x='-73.43' y='68.33' fill='url(%26quot%3b%23SvgjsPattern1067%26quot%3b)' transform='rotate(149.41%2c 83.35%2c 225.11)'%3e%3c/rect%3e%3crect width='238.72' height='238.72' clip-path='url(%26quot%3b%23SvgjsClipPath1068%26quot%3b)' x='137.27' y='299.54' fill='url(%26quot%3b%23SvgjsPattern1069%26quot%3b)' transform='rotate(289.98%2c 256.63%2c 418.9)'%3e%3c/rect%3e%3c/g%3e%3cdefs%3e%3cmask id='SvgjsMask1053'%3e%3crect width='1440' height='560' fill='white'%3e%3c/rect%3e%3c/mask%3e%3cpattern x='0' y='0' width='10.3' height='10.3' patternUnits='userSpaceOnUse' id='SvgjsPattern1055'%3e%3cpath d='M0 10.3L5.15 0L10.3 10.3' stroke='rgba(255%2c 85%2c 128%2c 1)' fill='none'%3e%3c/path%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1054'%3e%3ccircle r='25.75' cx='464.94' cy='37.43'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='360' height='6' patternUnits='userSpaceOnUse' id='SvgjsPattern1057'%3e%3crect width='360' height='3' x='0' y='0' fill='rgba(255%2c 85%2c 128%2c 1)'%3e%3c/rect%3e%3crect width='360' height='3' x='0' y='3' fill='rgba(0%2c 0%2c 0%2c 0)'%3e%3c/rect%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1056'%3e%3ccircle r='90' cx='1418.91' cy='372.58'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='13.66' height='13.66' patternUnits='userSpaceOnUse' id='SvgjsPattern1059'%3e%3cpath d='M6.83 1L6.83 12.66M1 6.83L12.66 6.83' stroke='rgba(255%2c 85%2c 128%2c 1)' fill='none' stroke-width='2.35'%3e%3c/path%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1058'%3e%3ccircle r='75.13' cx='1316.19' cy='523.53'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='6' height='6' patternUnits='userSpaceOnUse' id='SvgjsPattern1061'%3e%3cpath d='M3 1L3 5M1 3L5 3' stroke='rgba(255%2c 85%2c 128%2c 1)' fill='none' stroke-width='1'%3e%3c/path%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1060'%3e%3ccircle r='93' cx='480.72' cy='116.1'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='221.2' height='11.06' patternUnits='userSpaceOnUse' id='SvgjsPattern1063'%3e%3crect width='221.2' height='5.53' x='0' y='0' fill='rgba(255%2c 85%2c 128%2c 1)'%3e%3c/rect%3e%3crect width='221.2' height='5.53' x='0' y='5.53' fill='rgba(0%2c 0%2c 0%2c 0)'%3e%3c/rect%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1062'%3e%3ccircle r='55.3' cx='668.36' cy='157.24'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='6' height='6' patternUnits='userSpaceOnUse' id='SvgjsPattern1065'%3e%3cpath d='M0 6L3 0L6 6' stroke='rgba(255%2c 85%2c 128%2c 1)' fill='none'%3e%3c/path%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1064'%3e%3ccircle r='81' cx='821.01' cy='61.56'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='12.06' height='12.06' patternUnits='userSpaceOnUse' id='SvgjsPattern1067'%3e%3cpath d='M0 12.06L6.03 0L12.06 12.06' stroke='rgba(255%2c 85%2c 128%2c 1)' fill='none'%3e%3c/path%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1066'%3e%3ccircle r='78.39' cx='83.35' cy='225.11'%3e%3c/circle%3e%3c/clipPath%3e%3cpattern x='0' y='0' width='7.46' height='7.46' patternUnits='userSpaceOnUse' id='SvgjsPattern1069'%3e%3cpath d='M3.73 1L3.73 6.46M1 3.73L6.46 3.73' stroke='rgba(255%2c 85%2c 128%2c 1)' fill='none' stroke-width='2'%3e%3c/path%3e%3c/pattern%3e%3cclipPath id='SvgjsClipPath1068'%3e%3ccircle r='59.68' cx='256.63' cy='418.9'%3e%3c/circle%3e%3c/clipPath%3e%3c/defs%3e%3c/svg%3e")`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
            }}
                className="h-max lg:h-[500px] p-4">
                <div className="h-full w-full flex flex-col items-center justify-center p-4">
                    <Typography style={{ color: '#004080' }} className="font-varela text-center" variant={IsLargeScreen ? "h1" : "h2"}>Learn about Breastfeeding and more!</Typography>
                    <div className="w-[80%]">
                        <Typography variant={IsLargeScreen ? "lead" : "small"} className="mt-4 text-center">Welcome to our Articles Page! Here, you&apos;ll find a wealth of information about breastmilk, breastfeeding, and maternal health. Explore expert tips, inspiring stories, and the latest research to support your journey. Whether you&apos;re looking for advice, answers to common questions, or simply inspiration, this is your go-to resource for all things related to human milk and nurturing care.</Typography>
                    </div>
                    <div className="flex items-center lg:w-1/4 mt-4">
                        <Input
                            type="text"
                            className="bg-white"
                            label="Search for articles"
                            onChange={(e) => setSearch(e.target.value)}
                            value={search}
                        />
                        <Button className="bg-secondary" onClick={handleSearch}>Search</Button>
                    </div>
                </div>

            </section>
            <section className="p-4">
                <div className="flex flex-wrap gap-4">
                    <ArticleList articles={articles} isLargeScreen={IsLargeScreen} />

                </div>
            </section>
        </>
    )
}

export default Article