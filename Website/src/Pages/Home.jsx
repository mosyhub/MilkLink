import React, { useEffect } from 'react'
import { Link } from 'react-router-dom'
import StickyNavbar from '../Components/Navbar'
import { Button, Typography } from '@material-tailwind/react'
import { DefaultGallery } from '../Components/Gallery'
import donate from '../assets/image/donate.png'
import screening from '../assets/image/screening.png'
import signup from '../assets/image/signup.png'
import { AccordionCustomIcon } from '../Components/Accordion'
import UpcomingEvents from '../Components/Admin/Calendar/UpcomingEvents'
import { useDispatch, useSelector } from 'react-redux'
import { getUpcomingLettings } from '../redux/actions/lettingActions'
import Announcements from '../Components/Admin/Announcements/Announcements'

const Home = () => {
  const dispatch = useDispatch();
  const {lettings} = useSelector(state => state.lettings)
  
  useEffect(() => {
    dispatch(getUpcomingLettings());
    
  }, [dispatch])
  return (
    <>
      <StickyNavbar />
      <section
        className="hero h-[500px] p-4">
        <div className="mt-8 h-full w-full flex flex-col items-center justify-center px-4">
          <Typography

            className="font-dm text-white text-center text-4xl sm:text-3xl md:text-4xl lg:text-5xl max-w-3xl font-bold"
          >
            Welcome to Taguig City Human Milk Bank online portal!
          </Typography>

          <Typography
            variant="lead"
            className="font-parkinsans text-white mt-4 text-center text-lg sm:text-base md:text-lg lg:text-xl max-w-5xl"
          >
            Join our growing community of 1,800+ donors and help provide life-saving nourishment to infants in need.
          </Typography>

          <Typography
            variant="lead"
            className="font-parkinsans text-white text-center text-lg sm:text-base md:text-lg lg:text-xl max-w-xl"
          >
            Together, we can make a difference—one drop at a time.
          </Typography>

          <Link to="/donor-application">
            <Button
              color="pink"
              variant="gradient"
              size="lg"
              className="mt-4 w-full max-w-xs sm:max-w-sm"
            >
              Become a Donor Today
            </Button>
          </Link>
        </div>

      </section>

      <section className="p-4 mb-8">
        <div>
          <DefaultGallery />
        </div>
      </section>

      <section className="p-4 mb-8 w-full">
        <UpcomingEvents events={lettings} />
      </section>

      <section className="p-4 mb-8 w-full">
        <Announcements/>
      </section>

      <section className="h-max p-4 mb-24">
        <Typography variant="h1" style={{ color: '#004080' }} className="font-varela text-center">How TCHMB Portal works?</Typography>
        <div className="flex flex-col xl:flex-row justify-center items-center md:justify-evenly p-4">
          <div className="flex flex-col items-center">
            <img src={signup} alt="signup" className="max-w-96" />
            <Typography variant="h4" className="font-varela text-primary">STEP 1: SIGN UP</Typography>
            <Typography variant="paragraph" className="w-96 text-center">Sign up and complete our interview form to determine your eligibility as a donor based on your medical background.</Typography>
          </div>
          <div className="flex flex-col items-center">
            <img src={screening} alt="screening" className="max-w-96" />
            <Typography variant="h4" className="font-varela text-primary">STEP 2: SCREENING</Typography>
            <Typography variant="paragraph" className="w-96 text-center">Eligible donors will be contacted to schedule a blood screening for HIV, Hepatitis B, and Syphilis. This ensures the safety and quality of the breast milk donated</Typography>
          </div>
          <div className="flex flex-col items-center">
            <img src={donate} alt="donate" className="max-w-96" />
            <Typography variant="h4" className="font-varela text-primary">STEP 3: DONATE</Typography>
            <Typography variant="paragraph" className="w-96 text-center">Eligible donors can donate their excess breast milk through home pick-up or barangay clinics after screening.</Typography>
          </div>
        </div>
      </section>

      <section className="bg-white h-max p-4 relative" >
        <div className="custom-shape-divider-top-1736524383">
          <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none">
            <path d="M600,112.77C268.63,112.77,0,65.52,0,7.23V120H1200V7.23C1200,65.52,931.37,112.77,600,112.77Z" className="shape-fill"></path>
          </svg>
        </div>
        <div className="container mx-auto mt-24 p-10">
          <Typography variant="h1" style={{ color: '#004080' }} className="font-varela mb-4">Frequently Asked Questions</Typography>
          <AccordionCustomIcon />
        </div>

      </section>

    </>
  )
}

export default Home