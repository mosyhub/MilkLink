import React from 'react'
import { IconButton } from '@material-tailwind/react'
import { Link } from 'react-router-dom'

import { EyeIcon, SquarePenIcon } from 'lucide-react'
import DataTable from '../../../../Components/DataTables/tanstack/DataTable'
import { createColumnHelper } from '@tanstack/react-table'
import PropTypes from 'prop-types'

function ActionsCell({ row, handleEdit }) {
    const _id = row.original._id
    return (
        <div className="flex gap-2">
            <Link to={`/dashboard/inventory/fridge/pasteurized/${_id}`}>
                <IconButton className="text-secondary rounded-full" variant="text"><EyeIcon size={25} /></IconButton>
            </Link>
            <IconButton className="text-secondary rounded-full" variant="text"><SquarePenIcon size={22} onClick={() => handleEdit(_id)} /></IconButton>
        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
    handleEdit: PropTypes.func.isRequired,
}
const PastTables = ({ pasteurizedFridges, handleEdit }) => {
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.name, {
            id: 'fridgeName',
            header: 'Fridge Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.fridgeType, {
            id: 'fridgeType',
            header: 'Fridge Type',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.availableMilk, {
            id: 'totalVolume',
            header: 'Total Volume',
            cell: info => `${info.getValue()} ml`,
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (<ActionsCell row={row} handleEdit={handleEdit} />),
        }),
    ];
    return (
        <div className="w-full h-full">
            <DataTable data={pasteurizedFridges} columns={columns} pageSize={10} height="h-[calc(100vh-14rem)]"/>
        </div>
    )
}

PastTables.propTypes = {
    pasteurizedFridges: PropTypes.array.isRequired,
    handleEdit: PropTypes.func.isRequired
}

export default PastTables