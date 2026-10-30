import React from 'react'
import { createColumnHelper } from '@tanstack/react-table';
import DataTable from '../../DataTables/tanstack/DataTable';
import PropTypes from 'prop-types';

const AccountTable = ({ users }) => {
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.employeeID, {
            id: 'employeeID',
            header: 'Employee ID',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.name.first, {
            id: 'firstName',
            header: 'First Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.name.last, {
            id: 'lastName',
            header: 'Last Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.name.middle, {
            id: 'middleName',
            header: 'Middle Name',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.phone, {
            id: 'phone',
            header: 'Phone',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.email, {
            id: 'email',
            header: 'Email',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.role, {
            id: 'role',
            header: 'Role',
            cell: info => info.getValue()
        }),
    ];
    return (
        <div className="w-full h-full">
            <DataTable data={users} columns={columns} pageSize={10} />
        </div>
    )
}
AccountTable.propTypes = {
    users: PropTypes.arrayOf(
        PropTypes.shape({
            employeeID: PropTypes.string.isRequired,
            name: PropTypes.shape({
                first: PropTypes.string.isRequired,
                last: PropTypes.string.isRequired,
                middle: PropTypes.string
            }).isRequired,
            phone: PropTypes.string.isRequired,
            email: PropTypes.string.isRequired,
            role: PropTypes.string.isRequired
        })
    ).isRequired
}

export default AccountTable