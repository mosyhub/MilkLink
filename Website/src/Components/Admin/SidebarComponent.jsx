import React, { createContext, useContext, useEffect, useMemo, useState } from 'react'
import Sidebar, { SidebarItem } from './Sidebar'
import {
    LifeBuoy,
    Boxes,
    BarChart3,
    LayoutDashboard,
    HeartIcon,
    UserCircleIcon,
    CalendarIcon,
    UsersIcon,
    MegaphoneIcon,
    NewspaperIcon,
    ClockIcon,
    Box,
    PackageOpenIcon,
    BadgeCheck,
    Archive,
} from 'lucide-react'

import PropTypes from 'prop-types'
import { Drawer } from '@material-tailwind/react';
import { useIsMobile } from '../../utils/hooks/useIsMobile';

const SidebarContext = createContext();

const superAdminItems = [
    { title: "Donor Records", route: "/dashboard/donors", path: 'donor', icon: <HeartIcon className="text-secondary" size={20} />, category: "Records" },
    { title: "Recipient Records", route: "/dashboard/recipients", path: 'recipient', icon: <UserCircleIcon className="text-secondary" size={20} />, category: "Records" },
    { title: "Interview Form Submissions", route: "/dashboard/submissions", path: 'submission', icon: <BadgeCheck className="text-secondary" size={20} />, category: "Records" },
    { title: "Event Schedules", route: "/dashboard/events", path: 'event', icon: <CalendarIcon className="text-secondary" size={20} />, category: "Schedules" },
    { title: "Pick-up Schedules", route: "/dashboard/schedules", path: 'schedule', icon: <ClockIcon className="text-secondary" size={20} />, category: "Schedules" },

    { title: "Collections", route: "/dashboard/collections", path: 'collection', icon: <Boxes className="text-secondary" size={20} />, category: "Inventory" },
    { title: "Refrigerators", route: "/dashboard/inventory/refrigerator", path: 'inventory', icon: <Box className="text-secondary" size={20} />, category: "Inventory" },

    { title: "Requests", route: "/dashboard/requests", path: 'request', icon: <PackageOpenIcon className="text-secondary" size={20} />, category: "Inventory" },

    { title: "Account Management", route: "/dashboard/account", path: 'account', icon: <UsersIcon className="text-secondary" size={20} />, category: "Management" },
    { title: "Announcement Management", route: "/dashboard/announcement", path: 'announcement', icon: <MegaphoneIcon className="text-secondary" size={20} />, category: "Management" },
    { title: "Articles Management", route: "/dashboard/resources", path: 'resources', icon: <NewspaperIcon className="text-secondary" size={20} />, category: "Management" },
    { title: "Archive", route: "/dashboard/archive", path: 'archive', icon: <Archive className="text-secondary" size={20} />, category: "Archive" },

];

const staffItems = [
    { title: "Recipient Records", route: "/dashboard/recipients", path: 'recipient', icon: <UserCircleIcon className="text-secondary" size={20} />, category: "Records" },
    { title: "Request", route: "/dashboard/staff/requests", path: 'staff', icon: <LifeBuoy className="text-secondary" size={20} />, category: "Records" },
]

const SidebarComponent = ({ userDetails }) => {
    
    const roleMap = {
        Admin: superAdminItems,
        SuperAdmin: superAdminItems,
        Staff: staffItems,
    };

    const sidebarItems = roleMap[userDetails?.role] || [];


    const groupedItems = sidebarItems.reduce((acc, item) => {
        if (!item.category) return acc;
        acc[item.category] = acc[item.category] || [];
        acc[item.category].push(item);
        return acc;
    }, {});
    const {isMenuOpen, setIsMenuOpen} = useContext(SidebarContext);
    const handleOpen = () => setIsMenuOpen(!isMenuOpen);
   
    return (
        <>
            <main className="hidden md:block">
                <Sidebar userDetails={userDetails}>
                    {userDetails && (userDetails?.role === "Admin" || userDetails?.role === "SuperAdmin") &&
                        <>
                            <SidebarItem
                                icon={<LayoutDashboard className="text-secondary" size={20} />}
                                text="Dashboard"
                                path="/dashboard"
                                prefix="dashboard"

                            />

                            <SidebarItem
                                icon={<BarChart3 className="text-secondary" size={20} />}
                                text="Reports"
                                path="/dashboard/reports"
                                prefix="reports" />
                        </>
                    }

                    {Object.entries(groupedItems).map(([category, items]) => (
                        <div key={category}>

                            <span className="flex items-center">

                                <span className="h-px flex-1 bg-gray-400"></span>

                            </span>
                            {items.map((item) => (
                                <SidebarItem
                                    key={item.route}
                                    icon={item.icon}
                                    text={item.title}
                                    path={item.route}
                                    prefix={item.path}
                                />
                            ))}
                        </div>
                    ))}

                </Sidebar>
            </main>
            <Drawer open={isMenuOpen} onClose={handleOpen} size={300} className="p-4">
                <Sidebar userDetails={userDetails}>
                    {userDetails && (userDetails?.role === "Admin" || userDetails?.role === "SuperAdmin") &&
                        <>
                            <SidebarItem
                                icon={<LayoutDashboard className="text-secondary" size={20} />}
                                text="Dashboard"
                                path="/dashboard"
                                prefix="dashboard"

                            />

                            <SidebarItem
                                icon={<BarChart3 className="text-secondary" size={20} />}
                                text="Reports"
                                path="/dashboard/reports"
                                prefix="reports" />
                        </>
                    }

                    {Object.entries(groupedItems).map(([category, items]) => (
                        <div key={category}>

                            <span className="flex items-center">

                                <span className="h-px flex-1 bg-gray-400"></span>

                            </span>
                            {items.map((item) => (
                                <SidebarItem
                                    key={item.route}
                                    icon={item.icon}
                                    text={item.title}
                                    path={item.route}
                                    prefix={item.path}
                                />
                            ))}
                        </div>
                    ))}

                </Sidebar>
            </Drawer>
        </>
    )
}


export const SidebarComponentProvider = ({children}) => {
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    const value = useMemo(()=>({isMenuOpen, setIsMenuOpen}), [isMenuOpen, setIsMenuOpen]);

    return (
        <SidebarContext.Provider value={value}>
            {children}
        </SidebarContext.Provider>
    );
}

export const useSidebar = () => useContext(SidebarContext);

SidebarComponent.propTypes = {
    userDetails: PropTypes.object.isRequired
}
export default SidebarComponent