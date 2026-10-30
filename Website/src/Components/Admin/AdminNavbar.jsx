import React, { useEffect } from "react";
import {
  Navbar,
  Typography,
  Button,
  Menu,
  MenuHandler,
  MenuList,
  MenuItem,
  Breadcrumbs,
  IconButton,
} from "@material-tailwind/react";
import {
  ArrowLeftStartOnRectangleIcon,
  UserIcon
} from "@heroicons/react/24/solid";
import { useDispatch, useSelector } from "react-redux";
import { getUser, logoutUser } from "../../redux/actions/userActions";
import { Link, useNavigate } from "react-router-dom";
import { ChevronDown, MenuIcon } from "lucide-react";
import { useBreadcrumb } from "../Breadcrumb/BreadcrumbContext";
import PropTypes from "prop-types";
import { useSidebar } from "./SidebarComponent";

function ProfileMenu() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [isMenuOpen, setIsMenuOpen] = React.useState(false);
  const { userDetails } = useSelector(state => state.users);

  const logoutHandler = () => {
    dispatch(logoutUser('logged out'));

    setIsMenuOpen(false);
  }
  const goToProfile = () => {
    navigate('/dashboard/profile');
  }
  useEffect(() => {
    dispatch(getUser())
  }, [dispatch])
  // profile menu component
  const profileMenuItems = [
    {
      label: "Profile",
      icon: UserIcon,
      onPress: goToProfile
    },

    {
      label: "Logout",
      icon: ArrowLeftStartOnRectangleIcon,
      onPress: logoutHandler
    },
  ];



  return (
    <div className="hidden md:block">
      <Menu open={isMenuOpen} handler={setIsMenuOpen} placement="bottom-end">
        <MenuHandler>
          <Button
            variant="text"
            color="blue-gray"
            className="flex items-center gap-1 p-3 lg:ml-auto"
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
    </div>
  );
}

export function ComplexNavbar({ setIsNavOpen }) {

  const { breadcrumb } = useBreadcrumb();
  
  const toggleIsNavOpen = () => setIsNavOpen((cur) => !cur);
  
  useEffect(() => {
    window.addEventListener(
      "resize",
      () => window.innerWidth >= 960 && toggleIsNavOpen(),
    );
  }, []);
  const {setIsMenuOpen} = useSidebar();
  const handleOpen = () => setIsMenuOpen(curr => !curr)
  return (
    <Navbar className="top-0 z-10 mx-auto max-w-full p-2 rounded-none lg:pl-6">
      <div className="relative mx-auto flex items-center justify-between text-blue-gray-900">
        <IconButton variant="text" onClick={handleOpen} className="md:hidden">
        <MenuIcon size={20}/>
        </IconButton>
        <div className="flex">
          <Breadcrumbs className="bg-white">
            {breadcrumb.map((item, index) =>
              item.path && index !== breadcrumb.length - 1 ? (
                <Link key={item.name} to={item.path} className="text-blue-gray-800 hover:text-secondary hover:underline">
                  {item.name}
                </Link>
              ) : (
                <Typography key={item.name} color="blue-gray" className="font-semibold text-secondary">
                  {item.name}
                </Typography>
              )
            )}
          </Breadcrumbs>

        </div>
        <ProfileMenu />
      </div>

    </Navbar>
  );
}

ComplexNavbar.propTypes = {
  setIsNavOpen: PropTypes.func.isRequired
}