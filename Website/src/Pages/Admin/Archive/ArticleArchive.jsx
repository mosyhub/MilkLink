import React, { useState, useEffect } from 'react'
import { Input, IconButton } from '@material-tailwind/react'
import { Link } from 'react-router-dom'
import { ArrowLongLeftIcon, MagnifyingGlassIcon } from '@heroicons/react/24/solid';
import { useDispatch, useSelector } from 'react-redux';
import { getArchivedArticles, restoreArticle } from '../../../redux/actions/articleActions';
import { resetSuccess } from '../../../redux/slices/articleSlice';
import { createColumnHelper } from '@tanstack/react-table';
import DataTable from '../../../Components/DataTables/tanstack/DataTable';
import { formatDate } from '../../../utils/helper';
import { RotateCcw } from 'lucide-react';
import { toast } from 'react-toastify';
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext';
import PropTypes from 'prop-types'
function RestoreCell({ row , handleRestore}) {
  const article = row.original
  return (
    <div className="flex gap-2">
      <IconButton variant="text" className="text-secondary rounded-full"><RotateCcw size={22} className="text-secondary cursor-pointer" onClick={() => handleRestore(article._id)} /></IconButton>
    </div>
  );
}
RestoreCell.propTypes = {
    row: PropTypes.object.isRequired,
    handleRestore: PropTypes.func.isRequired,
}
const ArticleArchive = () => {
  const { setBreadcrumb } = useBreadcrumb();
  const dispatch = useDispatch();
  const { articles, success } = useSelector((state) => state.articles);
  const [search, setSearch] = useState('');


  const handleRestore = (id) => {
    dispatch(restoreArticle(id));
  }
  const handleTextChange = (e) => {
    setSearch(e.target.value);
  }
  const handleSubmit = () => {
    dispatch(getArchivedArticles(search));
  }
  useEffect(() => {
    setBreadcrumb([
      { name: "Dashboard", path: "/dashboard" },
      { name: "Archive", path: "/dashboard/archive" },
      { name: "Articles", path: "/dashboard/archive/articles" }
    ])
  }, [])

  useEffect(() => {
    dispatch(getArchivedArticles());
  }, [dispatch])
  useEffect(() => {
    dispatch(getArchivedArticles(search));
  }, [search, dispatch])
  useEffect(() => {
    if (success) {
      console.log("restored");
      toast.success("Article restored successfully");
      dispatch(resetSuccess());
      dispatch(getArchivedArticles());
    }
  }, [success, dispatch])
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
      header: 'Restore',
      cell: ({ row }) => (
        <RestoreCell row={row} handleRestore={handleRestore}/>
      ),
    }),
  ];
  return (
    <section className="w-full h-full">
      <div className="flex justify-between items-center h-max w-full mb-4">
        <Link to="/dashboard/archive" className="">
          <div className="h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/60 hover:text-gray-700 transition-all hover:cursor-pointer">
            <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
          </div>
        </Link>

        <div className="flex items-center justify-start gap-4">
          <div className="flex flex-col lg:flex-row items-center justify-between gap-4 w-full">
            <div className="flex justify-center items-center gap-4">
              <div className="relative flex w-full gap-2 md:w-max">
                <Input
                  type="search"
                  color="gray"
                  label="Search for articles..."
                  className="pr-10"
                  onChange={handleTextChange}
                  containerProps={{
                    className: "min-w-[288px] bg-white rounded-lg",
                  }}
                />
                <MagnifyingGlassIcon className="h-8 w-8 !absolute right-1 top-1 rounded text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer" onClick={handleSubmit} />

              </div>
            </div>
          </div>
        </div>
      </div>
      <DataTable data={articles} columns={columns} pageSize={10} />
    </section>
  )
}

export default ArticleArchive