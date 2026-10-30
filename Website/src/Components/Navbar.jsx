import React, { useEffect } from "react";
import {
  Navbar,
  Collapse,
  Typography,
  Button,
  IconButton,
  Menu,
  MenuHandler,
  MenuList,
  MenuItem,
} from "@material-tailwind/react";
import { PresentationChartBarIcon, ArrowLeftStartOnRectangleIcon } from "@heroicons/react/24/solid";
import { Link, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from 'react-redux';
import { logoutUser, getUser } from '../redux/actions/userActions';
import { ChevronDown } from "lucide-react";

function ProfileMenu() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [isMenuOpen, setIsMenuOpen] = React.useState(false);
  const [profileMenuItems, setProfileMenuItems] = React.useState([]);
  const { userDetails } = useSelector(state => state.users);
  useEffect(() => {
    dispatch(getUser());
  }, [dispatch])


  const logoutHandler = () => {

    dispatch(logoutUser('logged out'));
    setIsMenuOpen(false);
  }
  const goToDashboard = () => {
    if (userDetails.role === "Admin" || userDetails.role === "SuperAdmin") {
      navigate("/dashboard");
    }
    else if (userDetails.role === "Staff") {
      navigate("/dashboard/recipients");
    }
  }
  useEffect(() => {
    if (userDetails) {
      if (userDetails.role === "User") {
        setProfileMenuItems([

          {
            label: "Logout",
            icon: ArrowLeftStartOnRectangleIcon,
            onPress: logoutHandler
          },
        ])
      }
      else {
        setProfileMenuItems([
          {
            label: "Dashboard",
            icon: PresentationChartBarIcon,
            onPress: goToDashboard
          },

          {
            label: "Logout",
            icon: ArrowLeftStartOnRectangleIcon,
            onPress: logoutHandler
          },
        ])
      }

    }
  }, [userDetails]);




  return (
    <Menu open={isMenuOpen} handler={setIsMenuOpen} placement="bottom-end">
      <MenuHandler>
        <Button
          variant="text"
          color="white"
          className="flex items-center gap-1 py-0.5 p-3 pr-2 pl-2 lg:ml-auto"
        >
          Welcome, {userDetails ? (userDetails.name.first + " " + userDetails.name.last) : "Guest"} <ChevronDown />
        </Button>
      </MenuHandler>
      <MenuList className="p-1">
        {profileMenuItems.map(({ label, icon, onPress }, key) => {
          const isLastItem = key === profileMenuItems.length - 1;
          return (
            <MenuItem
              key={label}
              onClick={onPress}
              className={`flex items-center gap-2 rounded ${isLastItem
                ? "hover:bg-red-500/10 focus:bg-red-500/10 active:bg-red-500/10"
                : ""
                }`}
            >
              {React.createElement(icon, {
                className: `h-4 w-4 ${isLastItem ? "text-red-500" : ""}`,
                strokeWidth: 2,
              })}
              <Typography
                as="span"
                variant="small"
                className="font-normal"
                color={isLastItem ? "red" : "inherit"}
              >
                {label}
              </Typography>
            </MenuItem>
          );
        })}
      </MenuList>
    </Menu>
  );
}

const StickyNavbar = () => {
  const dispatch = useDispatch();
  const { userDetails } = useSelector(state => state.users);
  const [openNav, setOpenNav] = React.useState(false);

  const logoutHandler = () => {

    dispatch(logoutUser('logged out'));


  }

  useEffect(() => {
    window.addEventListener(
      "resize",
      () => window.innerWidth >= 960 && setOpenNav(false),
    );
  }, []);
  useEffect(() => {
    if (sessionStorage.getItem("user")) {
      dispatch(getUser())
    }

  }, [sessionStorage])


  const navList = (
    <ul className="mt-2 mb-4 flex flex-col gap-2 lg:mb-0 lg:mt-0 lg:flex-row lg:items-center lg:gap-6">
      <Typography
        as="li"
        variant="small"
        color="white"
        className="p-1 font-normal font-varela"
      >
        <Link to="/articles" className="flex items-center">
          Articles
        </Link>
      </Typography>
      {/* <Typography
        as="li"
        variant="small"
        color="white"
        className="p-1 font-normal font-varela"
      >
        <Link to="/about" className="flex items-center">
          About Us
        </Link>
      </Typography> */}

    </ul>
  );

  return (

    <Navbar className="sticky top-0 z-50 h-max max-w-full rounded-none px-4 py-2 lg:px-8 lg:py-4 bg-[#E53777]">
      <div className="flex items-center justify-between text-light">
        <Typography
          as="a"
          href="/"
          className="mr-4 cursor-pointer py-1.5  text-white font-bold font-varela"
        >
          TCHMB Portal
        </Typography>
        <div className="flex items-center gap-4">
          <div className="mr-4 hidden lg:block">{navList}</div>
          <div className="flex items-center gap-x-1">
            {userDetails ? (<div className="hidden lg:hidden-block"><ProfileMenu /></div>) : (
              <Link to="/login">
                <Button
                  variant="gradient"
                  size="sm"
                  color="white"
                  className="hidden lg:inline-block"
                >
                  <span>Log In</span>
                </Button>
              </Link>)}

          </div>
          <IconButton
            variant="text"
            className="ml-auto h-6 w-6 text-inherit hover:bg-transparent focus:bg-transparent active:bg-transparent lg:hidden"
            ripple={false}
            onClick={() => setOpenNav(!openNav)}
          >
            {openNav ? (
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                className="h-6 w-6"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            ) : (
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6"
                fill="none"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
            )}
          </IconButton>
        </div>
      </div>
      <Collapse open={openNav}>
        {navList}
        <div className="flex items-center gap-x-1">
          {userDetails ? (
            <Button
              variant="gradient"
              size="sm"
              color="white"
              className=""
              onClick={logoutHandler}
            >
              <span>Log out</span>
            </Button>) : (<Link to="/login">
              <Button
                variant="gradient"
                size="sm"
                color="white"
                className=""
              >
                <span>Log In</span>
              </Button>
            </Link>)}

        </div>
      </Collapse>
    </Navbar>


  );
}

export default StickyNavbar;