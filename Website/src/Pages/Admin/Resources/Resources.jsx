import React, { useState, useEffect } from 'react'
import { Button, Input, IconButton } from '@material-tailwind/react'
import { Link } from 'react-router-dom'
import { MagnifyingGlassIcon } from '@heroicons/react/24/solid';
import { useDispatch, useSelector } from 'react-redux';
import { getArticles, softDeleteArticle } from '../../../redux/actions/articleActions';
import { resetDelete } from '../../../redux/slices/articleSlice';
import { createColumnHelper } from '@tanstack/react-table';
import DataTable from '../../../Components/DataTables/tanstack/DataTable';
import { formatDate } from '../../../utils/helper';
import { Archive, EyeIcon, SquarePenIcon } from 'lucide-react';
import { toast } from 'react-toastify';
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext';
import PropTypes from 'prop-types';

function ActionsCell({ row, handleDelete }) {
    const article = row.original
    return (
        <div className="flex items-center gap-2">
            <Link to={`/article/${article._id}`}><IconButton variant="text" className="text-secondary rounded-full"><EyeIcon size={25} /></IconButton></Link>
            <Link to={`/dashboard/resources/edit/${article._id}`}><IconButton variant="text" className="text-secondary rounded-full"><SquarePenIcon size={22} className="text-secondary" /></IconButton></Link>
            <IconButton variant="text" className="text-secondary rounded-full"><Archive size={22} className="text-secondary cursor-pointer" onClick={() => handleDelete(article._id)} /></IconButton>

        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
    handleDelete: PropTypes.func.isRequired,
}

const Resources = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();
    const { articles, isDeleted } = useSelector((state) => state.articles);
    const [search, setSearch] = useState('');


    const handleDelete = (id) => {
        dispatch(softDeleteArticle(id));
    }
    const handleReset = () => {
        setSearch('');
    }
    const handleTextChange = (e) => {
        setSearch(e.target.value);
    }
    const handleSubmit = () => {
        dispatch(getArticles(search));
    }


    useEffect(() => {
        dispatch(getArticles());
    }, [dispatch])
    useEffect(() => {
        dispatch(getArticles(search));
    }, [search])
    useEffect(() => {
        if (isDeleted) {
            console.log("deleted");
            toast.success("Article archived successfully");
            dispatch(resetDelete());
            dispatch(getArticles());
        }
    }, [isDeleted, dispatch])
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => row.title, {
            id: 'title',
            header: 'Title',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.description, {
            id: 'description',
            header: 'Description',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => formatDate(row.createdAt), {
            id: 'createdAt',
            header: 'Date Published',
            cell: info => info.getValue(),
        }),

        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (<ActionsCell row={row} handleDelete={handleDelete} />),
        }),
    ];
    useEffect(() => {
        setBreadcrumb([
            { name: 'Dashboard', path: '/dashboard' },
            { name: 'Articles' }
        ])
    }, [])
    return (
        <section className="p-4">
            <div className="flex w-full items-center justify-start gap-4">
                <div className="flex flex-col lg:flex-row items-center justify-between gap-4 w-full mb-4">
                    <div className="flex justify-center items-center gap-4">
                        <div className="relative flex w-full gap-2 md:w-max">
                            <Input
                                type="search"
                                color="gray"
                                label="Search for articles..."
                                className="pr-10"
                                onChange={handleTextChange}
                                containerProps={{
                                    className: "min-w-[288px]",
                                }}
                            />
                            <MagnifyingGlassIcon className="h-8 w-8 !absolute right-1 top-1 rounded text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer" onClick={handleSubmit} />
                        </div>
                    </div>
                    <div className="flex items-center justify-center gap-4">
                        <div className="w-max">
                            <Button onClick={handleReset} className='bg-secondary w-max' size="sm">Delete filters</Button>
                        </div>
                        <Link to="/dashboard/resources/create" className="w-max">
                            <Button className="bg-secondary" size="sm">
                                Create New Article
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>
            <DataTable data={articles} columns={columns} pageSize={10} />
        </section>
    )
}

export default Resources