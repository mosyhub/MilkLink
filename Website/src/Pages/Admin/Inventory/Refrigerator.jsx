import React, { useState, useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { addFridges, getFridgeDetails, getFridges, updateFridge } from '../../../redux/actions/fridgeActions'
import UnpastTables from './tables/UnpastTables'
import PastTables from './tables/PastTables'
import {
    Tabs,
    TabsHeader,
    TabsBody,
    Tab,
    TabPanel,
    Button,
    Drawer,
    Card,
    CardHeader,
    Typography,
    CardBody,
    Input,
} from "@material-tailwind/react";
import Loader from '../../../Components/Loader/Loader'
import Select from 'react-select';
import { toast } from 'react-toastify'
import { resetUpdate } from '../../../redux/slices/fridgeSlice'
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext'
import PropTypes from 'prop-types'
function CustomOption({ option }) {
    return (
        <div className="flex flex-col text-sm">
            <span className="font-semibold">{option.value}</span>
        </div>
    )
}
CustomOption.propTypes = {
    option: PropTypes.object.isRequired,
}
const Refrigerator = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch()
    const { fridgeDetails, fridges, available, loading, isUpdated } = useSelector(state => state.fridges)
    useEffect(() => {
        dispatch(getFridges())
    }, [dispatch])
    const pasteurizedFridges = fridges ? fridges.filter((f) => f.fridgeType === 'Pasteurized') : [];
    const unpasteurizedFridges = fridges ? fridges.filter((f) => f.fridgeType === 'Unpasteurized') : [];
    const [open, setOpen] = useState(false)
    const [openEdit, setOpenEdit] = useState(false)
    const [id, setId] = useState('');
    const handleEdit = (id) => {
        dispatch(getFridgeDetails(id));
        setId(id);
        setOpenEdit(!open);
    }
    const handleOpen = () => setOpen(!open);
    const [formData, setFormData] = useState(() => ({
        name: '',
        fridgeType: ''
    }));
    useEffect(() => {
        setBreadcrumb([
            { name: 'Dashboard', path: '/dashboard' },
            { name: 'Refrigerators' }
        ])
    }, [])
    useEffect(() => {
        setFormData({
            name: fridgeDetails.name,
            fridgeType: fridgeDetails.fridgeType
        })
        setSelectedOption(fridgeDetails.fridgeType)
    }, [fridgeDetails])

    const [selectedOption, setSelectedOption] = useState('')
    const handleSubmit = () => {
        if (!formData.name || !formData.fridgeType) {
            toast.error('Please fill out all fields.');
            return;
        }

        const newFridge = {
            name: formData.name,
            fridgeType: formData.fridgeType,
        };

        dispatch(addFridges(newFridge))
            .then(() => {
                toast.success(`Fridge "${formData.name}" has been added successfully.`);
                setFormData({ name: '', fridgeType: '' });
            })
            .catch((error) => {
                toast.error('Failed to add fridge. Please try again.');
                console.error(error);
            });
        setOpen(!open);
    }
    const handleUpdate = () => {
        const updatedFridge = {
            id,
            name: formData.name,
            fridgeType: formData.fridgeType
        };
        dispatch(updateFridge(updatedFridge)).then(() => {
            toast.success("Updated successfully")
        }).catch((e) => {
            toast.error(`Error: ${e}`);
        })
        setOpenEdit(false);
    }
    const options = [
        { value: 'Unpasteurized', label: 'Unpasteurized' },
        { value: 'Pasteurized', label: 'Pasteurized' }
    ]
    useEffect(() => {
        dispatch(getFridges())
        if (isUpdated) {
            dispatch(resetUpdate());
        }
    }, [isUpdated])
    return (
        <div className="p-4">
            <Tabs value="Unpasteurized">
                <Button color="pink" size="sm" className="mb-2" variant="outlined" onClick={handleOpen}>
                    Add Fridge
                </Button>
                <TabsHeader>
                    <Tab value="Unpasteurized" className="text-secondary">
                        Unpasteurized
                    </Tab>
                    <Tab value="Pasteurized" className="text-secondary">
                        Pasteurized
                    </Tab>
                </TabsHeader>
                <TabsBody className="h-[calc(100vh-8rem)]" animate={{ initial: { opacity: 1 }, mount: { opacity: 1 }, unmount: { opacity: 0 } }}>
                    <TabPanel value="Unpasteurized" className="h-full">
                        <UnpastTables unpasteurizedFridges={unpasteurizedFridges} handleEdit={handleEdit} />
                    </TabPanel>
                    <TabPanel value="Pasteurized" className="h-full">
                        <PastTables available={available} pasteurizedFridges={pasteurizedFridges} handleEdit={handleEdit} />
                    </TabPanel>
                </TabsBody>
            </Tabs>
            <Drawer open={open} onClose={handleOpen} size={500} className="p-4" dismiss={{ outsidePress: false }}>
                <div className="overflow-y-auto h-[calc(100vh-5rem)] pr-2 space-y-4">
                    <Card className='w-full mx-auto mb-4' shadow={false}>
                        <CardHeader floated={false} shadow={false}>
                            <Typography variant="h4" color="blue-gray" className="mb-2">
                                Create new fridge
                            </Typography>
                            <Typography color="gray" className="font-normal">
                                Enter fridge details
                            </Typography>
                        </CardHeader>
                        <CardBody>
                            <div className="w-100 max-w-screen-lg">
                                <div className="mb-1 flex flex-col gap-4">

                                    <Typography variant="h6" color="blue-gray" className="-mb-3">
                                        Name
                                    </Typography>
                                    <Input
                                        size="sm"
                                        placeholder="Name"
                                        className=" !border-t-blue-gray-200 focus:!border-t-gray-900"
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        labelProps={{
                                            className: "before:content-none after:content-none",
                                        }}
                                    />
                                    <Typography variant="h6" color="blue-gray" className="-mb-3">
                                        Fridge type
                                    </Typography>
                                    <Select
                                        options={options}
                                        className="w-full select-border-black"
                                        value={options.find(opt => opt.value === selectedOption)}
                                        onChange={(selected) => { setFormData({ ...formData, fridgeType: selected.value }); setSelectedOption(selected.value) }}
                                        isSearchable
                                        formatOptionLabel={(option) => (<CustomOption option={option} />)}
                                    />

                                </div>
                            </div>
                        </CardBody>
                    </Card>
                </div>
                <div className="flex items-center justify-center w-full gap-4">
                    {loading ? <Loader /> : <>
                        <Button color="pink" onClick={handleSubmit} fullWidth>
                            Submit
                        </Button>
                        <Button color="black" onClick={handleOpen} fullWidth>
                            Close
                        </Button>
                    </>}
                </div>

            </Drawer>
            <Drawer open={openEdit} onClose={() => setOpenEdit(!openEdit)} size={500} className="p-4" dismiss={{ outsidePress: false }}>
                <div className="overflow-y-auto h-[calc(100vh-5rem)] pr-2 space-y-4">
                    <Card className='w-full mx-auto mb-4' shadow={false}>
                        <CardHeader floated={false} shadow={false}>
                            <Typography variant="h4" color="blue-gray" className="mb-2">
                                Edit fridge details
                            </Typography>
                            <Typography color="gray" className="font-normal">
                                Change fridge name
                            </Typography>
                        </CardHeader>
                        <CardBody>
                            <div className="w-100 max-w-screen-lg">
                                <div className="mb-1 flex flex-col gap-4">

                                    <Typography variant="h6" color="blue-gray" className="-mb-3">
                                        Name
                                    </Typography>
                                    <Input
                                        size="sm"
                                        placeholder="Name"
                                        className=" !border-t-blue-gray-200 focus:!border-t-gray-900"
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        labelProps={{
                                            className: "before:content-none after:content-none",
                                        }}
                                    />
                                    <Typography variant="h6" color="blue-gray" className="-mb-3">
                                        Fridge type
                                    </Typography>
                                    <Select
                                        options={options}
                                        className="w-full select-border-black"
                                        value={options.find(opt => opt.value === selectedOption)}
                                        onChange={(selected) => { setFormData({ ...formData, fridgeType: selected.value }); setSelectedOption(selected.value) }}
                                        isSearchable
                                        formatOptionLabel={(option) => (<CustomOption option={option} />)}
                                    />

                                </div>
                            </div>
                        </CardBody>
                    </Card>
                </div>
                <div className="flex items-center justify-center w-full gap-4">
                    {loading ? <Loader /> : <>
                        <Button color="pink" onClick={handleUpdate} fullWidth>
                            Submit
                        </Button>
                        <Button color="black" onClick={() => setOpenEdit(!openEdit)} fullWidth>
                            Close
                        </Button>
                    </>}
                </div>

            </Drawer>
        </div>
    )
}

export default Refrigerator