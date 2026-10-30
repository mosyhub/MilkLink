import { createColumnHelper } from '@tanstack/react-table';
import React, { useEffect } from 'react'
import DataTable from '../../../Components/DataTables/tanstack/DataTable';
import { Link } from 'react-router-dom';
import { EyeIcon } from 'lucide-react';
import { IconButton } from '@material-tailwind/react';
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext';
import PropTypes from 'prop-types'
function ActionCell({ row }) {
    return (
        <div className="flex gap-2">
            <Link to={row.original.route}>
                <IconButton variant="text" className="text-secondary rounded-full"><EyeIcon size={25} /></IconButton>
            </Link>
        </div>
    );
}
ActionCell.propTypes = {
    row: PropTypes.object.isRequired,
}
const Archive = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const data = [
        {
            section: "Announcements",
            route: '/dashboard/archive/announcements'
        },
        {
            section: "Resources",
            route: '/dashboard/archive/resources'
        }
    ]
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.section, {
            id: 'section',
            header: 'Section',
            cell: info => info.getValue(),
        }),

        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (<ActionCell row={row} />),
        }),
    ];
    useEffect(() => {
        setBreadcrumb([
            { name: 'Dashboard', path: '/dashboard' },
            { name: 'Archive' }
        ])
    }, [])
    return (
        <DataTable data={data} columns={columns} pageSize={10} />
    )
}

export default Archive