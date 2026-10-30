import React, { useEffect, useState } from 'react'
import { Viewer, Worker } from '@react-pdf-viewer/core';
import { defaultLayoutPlugin } from '@react-pdf-viewer/default-layout';
import '@react-pdf-viewer/core/lib/styles/index.css';
import '@react-pdf-viewer/default-layout/lib/styles/index.css';
import { Page, Text, View, Document, StyleSheet, Image, pdf } from '@react-pdf/renderer';
import { useDispatch, useSelector } from 'react-redux';
import { getDispensedMilkPerMonth, getDonorsPerMonth, getMilkPerMonth, getPasteurizedMilkPerMonth, getPatientsPerMonth } from '../../../redux/actions/metricActions';
import { normalizeData } from '../../../utils/helper';
import Select from 'react-select';
import { Typography, Drawer, Button, IconButton, Input } from '@material-tailwind/react';
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext';
import PropTypes from 'prop-types';
import header from '../../../assets/image/report_header.png'
import { CogIcon } from 'lucide-react';
import { getSignatories, updateSignatories } from '../../../redux/actions/signActions';
import Loader from '../../../Components/Loader/Loader';
import { resetUpdate } from '../../../redux/slices/signSlice';
// Styles
const styles = StyleSheet.create({
    page: {
        padding: 40,
        paddingTop: 20,
        fontSize: 10,
        flexDirection: 'column',
    },
    table: {
        display: 'table',
        width: '100%',
        borderStyle: 'solid',
        borderWidth: 1,
        borderRightWidth: 0,
        borderBottomWidth: 0,
    },
    row: {
        flexDirection: 'row',
    },
    multiCol: {
        borderRightWidth: 1,
        borderBottomWidth: 1,
        flexDirection: 'column',
        width: '42.9%',
        height: 'auto'
    },
    innerCol: {
        flexDirection: 'row',
        width: '100%',

    },
    col: {
        borderRightWidth: 1,
        backgroundColor: '#f2f2f2',
        borderStyle: 'solid',
        padding: 5,
        textAlign: 'center',
        fontWeight: 'bold',
    },
    cell: {
        flex: 1,
        borderRightWidth: 1,
        borderBottomWidth: 1,
        borderStyle: 'solid',
        padding: 5,
        textAlign: 'center',
        width: '12%',
    },
    colMonth: { width: '13%' },
    colWide: { width: '13%' },
    headerColumn: {

        textAlign: 'center',
        fontWeight: 'bold',
        backgroundColor: '#eee',
        padding: 5
    },
    totalCol: {
        backgroundColor: '#f4cccc',
    },
    totalRow: {
        backgroundColor: '#fff200',
        fontWeight: 'bold',
    },
    header: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        paddingBottom: '8px',
    },
    headerText: {
        fontSize: 12,
        fontWeight: 'bold',
        marginBottom: 4,
    }
});

const MyDocument = ({ year, page1_data, page1_total, page2_data, page2_total, signs }) => (
    <Document>
        <Page size="LEGAL" orientation="landscape" style={styles.page}>
            <View style={styles.header}>
                <Image src={header} style={{ width: '300px', height: 75, marginHorizontal: 'auto', marginBottom: '8px' }} />
                <Text style={styles.headerText}>Report {year.value}</Text>
            </View>
            <View style={styles.table}>
                {/* Header Row 1 */}
                <View style={styles.row}>
                    <Text style={[styles.cell, styles.colMonth, styles.headerColumn]} >MONTH</Text>
                    <View style={styles.multiCol}>
                        <Text style={[styles.col, styles.headerColumn, { borderRightWidth: 0, borderBottomWidth: 1 }]}>BREASTMILK DONORS</Text>
                        <View style={styles.innerCol}>
                            <Text style={[styles.col, styles.headerColumn, { flex: 1 }]}>Community</Text>
                            <Text style={[styles.col, styles.headerColumn, { flex: 1 }]}>Private</Text>
                            <Text style={[styles.col, styles.headerColumn, { borderRightWidth: 0, flex: 1 }]}>Total</Text>
                        </View>
                    </View>

                    <Text style={[styles.cell, styles.headerColumn]} hyphenationCallback={(word) => [word]}>INPATIENT RECIPIENT</Text>
                    <Text style={[styles.cell, styles.headerColumn]} hyphenationCallback={(word) => [word]}>OUTPATIENT RECIPIENT</Text>
                    <Text style={[styles.cell, styles.headerColumn]} hyphenationCallback={(word) => [word]}>TOTAL RECIPIENT</Text>
                </View>

                {/* Table Data */}
                {page1_data.map((row, index) => (
                    <View style={styles.row} key={row[index]}>
                        <Text style={[styles.cell, styles.colMonth]}>{row[0]}</Text>
                        <Text style={styles.cell}>{row[1]}</Text>
                        <Text style={styles.cell}>{row[2]}</Text>
                        <Text style={[styles.cell, styles.totalCol]}>{row[3]}</Text>
                        <Text style={styles.cell}>{row[4]}</Text>
                        <Text style={styles.cell}>{row[5]}</Text>
                        <Text style={[styles.cell, styles.totalCol]}>{row[6]}</Text>
                    </View>
                ))}

                {/* Total Row */}
                <View style={[styles.row, styles.totalRow]}>
                    <Text style={[styles.cell, styles.colMonth]}>{page1_total[0]}</Text>
                    <Text style={styles.cell}>{page1_total[1]}</Text>
                    <Text style={styles.cell}>{page1_total[2]}</Text>
                    <Text style={styles.cell}>{page1_total[3]}</Text>
                    <Text style={styles.cell}>{page1_total[4]}</Text>
                    <Text style={styles.cell}>{page1_total[5]}</Text>
                    <Text style={styles.cell}>{page1_total[6]}</Text>
                </View>
            </View>
            <View style={{ width: '100%', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', marginTop: 20, marginBottom: 20 }}>
                <Text style={{ fontSize: 11, width: '100%' }}>Prepared by:</Text>
                <Text style={{ fontSize: 11, width: '100%' }}>Checked by:</Text>
                <Text style={{ fontSize: 11, width: '100%' }}>Noted by:</Text>
            </View>
            <View style={{ width: '100%', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', marginTop: 20 }}>
                <Text style={{ fontSize: 9, width: '100%', fontWeight: 'bold' }}>{signs?.preparedBy?.name}</Text>
                <Text style={{ fontSize: 9, width: '100%', fontWeight: 'bold' }}>{signs?.checkedBy?.name}</Text>
                <Text style={{ fontSize: 9, width: '100%', fontWeight: 'bold' }}>{signs?.notedBy?.name}</Text>
            </View>
            <View style={{ width: '100%', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', marginTop: 5 }}>
                <Text style={{ fontSize: 9, width: '100%' }}>{signs?.preparedBy?.position}</Text>
                <Text style={{ fontSize: 9, width: '100%' }}>{signs?.checkedBy?.position}</Text>
                <Text style={{ fontSize: 9, width: '100%' }}>{signs?.notedBy?.position}</Text>
            </View>
        </Page>
        <Page size="LEGAL" orientation="landscape" style={styles.page}>
            <View style={styles.header}>
                <Image src={header} style={{ width: '300px', height: 75, marginHorizontal: 'auto', marginBottom: '8px' }} />
                <Text style={styles.headerText}>Report {year.value}</Text>
            </View>
            <View style={styles.table}>
                {/* Header Row 1 */}
                <View style={styles.row}>
                    <Text style={[styles.cell, styles.colMonth, styles.headerColumn]} >MONTH</Text>



                    <View style={[styles.multiCol, { width: '37.5%' }]}>
                        <Text style={[styles.col, styles.headerColumn, { borderRightWidth: 0, borderBottomWidth: 1 }]}>BREASTMILK COLLECTED (Liter)</Text>
                        <View style={styles.innerCol}>
                            <Text style={[styles.col, styles.headerColumn, { flex: 1 }]}>Milk Letting</Text>
                            <Text style={[styles.col, styles.headerColumn, { flex: 1 }]}>Private</Text>
                            <Text style={[styles.col, styles.headerColumn, { borderRightWidth: 0, flex: 1 }]}>Total</Text>
                        </View>
                    </View>

                    <View style={[styles.multiCol, { width: '37.5%' }]}>
                        <Text style={[styles.col, styles.headerColumn, { borderRightWidth: 0, borderBottomWidth: 1 }]}>BREASTMILK DISPENSED (Liter)</Text>
                        <View style={styles.innerCol}>
                            <Text style={[styles.col, styles.headerColumn, { flex: 1 }]}>Inpatient</Text>
                            <Text style={[styles.col, styles.headerColumn, { flex: 1 }]}>Outpatient</Text>
                            <Text style={[styles.col, styles.headerColumn, { borderRightWidth: 0, flex: 1 }]}>Total</Text>
                        </View>
                    </View>

                    <Text style={[styles.cell, styles.headerColumn]} hyphenationCallback={(word) => [word]}>BREASTMILK PASTEURIZED (Liter)</Text>
                </View>

                {/* Table Data */}
                {page2_data.map((row, index) => (
                    <View style={styles.row} key={row[index]}>
                        <Text style={[styles.cell, styles.colMonth]}>{row[0]}</Text>
                        <Text style={styles.cell}>{row[1]}</Text>
                        <Text style={styles.cell}>{row[2]}</Text>
                        <Text style={[styles.cell, styles.totalCol]}>{row[3]}</Text>
                        <Text style={styles.cell}>{row[4]}</Text>
                        <Text style={styles.cell}>{row[5]}</Text>
                        <Text style={[styles.cell, styles.totalCol]}>{row[6]}</Text>
                        <Text style={styles.cell}>{row[7]}</Text>
                    </View>
                ))}

                {/* Total Row */}
                <View style={[styles.row, styles.totalRow]}>
                    <Text style={[styles.cell, styles.colMonth]}>{page2_total[0]}</Text>
                    <Text style={styles.cell}>{page2_total[1]}</Text>
                    <Text style={styles.cell}>{page2_total[2]}</Text>
                    <Text style={styles.cell}>{page2_total[3]}</Text>
                    <Text style={styles.cell}>{page2_total[4]}</Text>
                    <Text style={styles.cell}>{page2_total[5]}</Text>
                    <Text style={styles.cell}>{page2_total[6]}</Text>
                    <Text style={styles.cell}>{page2_total[7]}</Text>
                </View>
            </View>
            <View style={{ width: '100%', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', marginTop: 20, marginBottom: 20 }}>
                <Text style={{ fontSize: 11, width: '100%' }}>Prepared by:</Text>
                <Text style={{ fontSize: 11, width: '100%' }}>Checked by:</Text>
                <Text style={{ fontSize: 11, width: '100%' }}>Noted by:</Text>
            </View>
            <View style={{ width: '100%', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', marginTop: 20 }}>
                <Text style={{ fontSize: 9, width: '100%', fontWeight: 'bold' }}>{signs?.preparedBy?.name}</Text>
                <Text style={{ fontSize: 9, width: '100%', fontWeight: 'bold' }}>{signs?.checkedBy?.name}</Text>
                <Text style={{ fontSize: 9, width: '100%', fontWeight: 'bold' }}>{signs?.notedBy?.name}</Text>
            </View>
            <View style={{ width: '100%', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', marginTop: 5 }}>
                <Text style={{ fontSize: 9, width: '100%' }}>{signs?.preparedBy?.position}</Text>
                <Text style={{ fontSize: 9, width: '100%' }}>{signs?.checkedBy?.position}</Text>
                <Text style={{ fontSize: 9, width: '100%' }}>{signs?.notedBy?.position}</Text>
            </View>
        </Page>
    </Document>
);
MyDocument.propTypes = {
    year: PropTypes.object,
    page1_data: PropTypes.array,
    page1_total: PropTypes.array,
    page2_data: PropTypes.array,
    page2_total: PropTypes.array,
    signs: PropTypes.object
}
const DonorsPerMonth = () => {
    const { setBreadcrumb } = useBreadcrumb()
    const dispatch = useDispatch();
    const { stats, monthlyDonors, dispensedMilk, monthlyPatients, pastPerMonth } = useSelector((state) => state.metrics);
    const [pdfUrl, setPdfUrl] = useState(null);
    const defaultLayoutPluginInstance = defaultLayoutPlugin();
    const [selectedYear, setSelectedYear] = useState(null);
    const { signs, loading, isUpdated } = useSelector((state) => state.signs);
    // Data rows
    const months = [
        'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
        'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    const currentYear = new Date().getFullYear();
    const startYear = 2020;

    const yearOptions = [];

    for (let year = startYear; year <= currentYear; year++) {
        yearOptions.push({ value: year, label: year.toString() });
    }
    const handleChange = (selectedOption) => {
        setSelectedYear(selectedOption);

    };
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Reports", path: "/dashboard/reports" },
        ])
    }, [])
    useEffect(() => {
        const generatePdf = async (page1_data, page1_total, page2_data, page2_total, signs) => {
            const blob = await pdf(<MyDocument year={selectedYear} page1_data={page1_data} page1_total={page1_total} page2_data={page2_data} page2_total={page2_total} signs={signs[0]} />).toBlob();
            setPdfUrl(URL.createObjectURL(blob));
        }
        generatePdf.propTypes = {
            page1_data: PropTypes.array.isRequired,
            page1_total: PropTypes.array.isRequired,
            page2_data: PropTypes.array.isRequired,
            page2_total: PropTypes.array.isRequired,
            signs: PropTypes.array.isRequired,
        }
        if (monthlyDonors && monthlyPatients && stats && dispensedMilk && pastPerMonth && signs) {
            const { page1_data, page1_total, page2_data, page2_total } = normalizeData(months, monthlyDonors, monthlyPatients, stats, dispensedMilk, pastPerMonth);

            generatePdf(page1_data, page1_total, page2_data, page2_total, signs);
        }

    }, [monthlyDonors, monthlyPatients, stats, dispensedMilk, pastPerMonth, signs])
    useEffect(() => {
        dispatch(getDonorsPerMonth());
        dispatch(getPatientsPerMonth());
        dispatch(getMilkPerMonth());
        dispatch(getDispensedMilkPerMonth());
        dispatch(getPasteurizedMilkPerMonth());
        dispatch(getSignatories());
        setSelectedYear({ value: currentYear, label: currentYear.toString() })
    }, [dispatch])
    useEffect(() => {
        if (selectedYear) {
            dispatch(getDonorsPerMonth({ year: selectedYear.value }));
            dispatch(getPatientsPerMonth({ year: selectedYear.value }));
            dispatch(getMilkPerMonth({ year: selectedYear.value }));
            dispatch(getDispensedMilkPerMonth({ year: selectedYear.value }));
            dispatch(getPasteurizedMilkPerMonth({ year: selectedYear.value }))
        }

    }, [dispatch, selectedYear])
    const [open, setOpen] = useState(false);
    const closeDrawer = () => {
        setOpen(!open);
    }
    const [formData, setFormData] = useState(() => ({
        preparedBy: { name: '', position: '' },
        checkedBy: { name: '', position: '' },
        notedBy: { name: '', position: '' }
    }))
    const handleNameChange = (e, role) => {
        setFormData((prev) => ({
            ...prev,
            [role]: { ...prev[role], name: e.target.value }
        }));
    }
    const handlePositionChange = (e, role) => {
        setFormData((prev) => ({
            ...prev,
            [role]: { ...prev[role], position: e.target.value }
        }));
    }
    const onSave = (e) => {
        e.preventDefault();
        const data = {
            id: signs[0]._id,
            newSignatories: {
                preparedBy: {
                    name: formData.preparedBy.name || signs[0].preparedBy.name,
                    position: formData.preparedBy.position || signs[0].preparedBy.position
                },
                checkedBy: {
                    name: formData.checkedBy.name || signs[0].checkedBy.name,
                    position: formData.checkedBy.position || signs[0].checkedBy.position
                },
                notedBy: {
                    name: formData.notedBy.name || signs[0].notedBy.name,
                    position: formData.notedBy.position || signs[0].notedBy.position
                }
            }
        }
        dispatch(updateSignatories(data))
    }
    useEffect(() => {
        if (signs && signs.length > 0) {
            setFormData({
                preparedBy: { name: signs[0].preparedBy.name, position: signs[0].preparedBy.position },
                checkedBy: { name: signs[0].checkedBy.name, position: signs[0].checkedBy.position },
                notedBy: { name: signs[0].notedBy.name, position: signs[0].notedBy.position }
            })
        }
    }, [signs])
    useEffect(()=>{
        if (isUpdated) {
            dispatch(getSignatories());
            setOpen(false);
            dispatch(resetUpdate());
        }
    },[isUpdated])
    return (
        <>
            <div className="flex gap-4 items-center mb-4">
                <Typography variant="h5">Year:</Typography>
                <Select
                    options={yearOptions}
                    value={selectedYear}
                    onChange={handleChange}
                    placeholder="Select year"
                    className="w-max z-20"
                />
                <IconButton color="pink" className="ml-auto" onClick={closeDrawer}>
                    <CogIcon className="h-6 w-6" />
                </IconButton>
            </div>

            <Worker workerUrl={`https://unpkg.com/pdfjs-dist@3.11.174/build/pdf.worker.min.js`}>
                <div className="h-[80vh]">
                    {pdfUrl ? <Viewer fileUrl={pdfUrl} plugins={[defaultLayoutPluginInstance]} /> : <p>Loading...</p>}
                </div>
            </Worker>
            <Drawer open={open} onClose={closeDrawer} size={400} className="p-4">
                <div className="mb-2 flex items-center justify-between">
                    <Typography variant="h5" color="black">
                        Settings
                    </Typography>
                    <IconButton variant="text" color="black" onClick={closeDrawer}>
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            strokeWidth={2}
                            stroke="currentColor"
                            className="h-5 w-5"
                        >
                            <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                d="M6 18L18 6M6 6l12 12"
                            />
                        </svg>
                    </IconButton>
                </div>
                <Typography variant="paragraph" className="pr-16" color="black">
                    Change the name of signatories and their positions.
                </Typography>
                <span className="flex items-center my-4">
                    <span className="h-px flex-1 bg-gray-500"></span>
                </span>
                <form onSubmit={onSave}>
                    <div className="mb-4">
                        <Typography variant="h5" color="black" className="mb-2 pr-4 font-normal">
                            Prepared by:
                        </Typography>
                        <div className="mb-4">
                            <Input value={formData?.preparedBy?.name} type="text" label="Name" onChange={(e) => handleNameChange(e, 'preparedBy')} />
                        </div>
                        <div className="mb-4">
                            <Input value={formData?.preparedBy?.position} type="text" label="Position" onChange={(e) => handlePositionChange(e, 'preparedBy')} />
                        </div>
                    </div>
                    <div className="mb-4">
                        <Typography variant="h5" color="black" className="mb-2 pr-4 font-normal">
                            Checked by:
                        </Typography>
                        <div className="mb-4">
                            <Input type="text" value={formData?.checkedBy?.name} label="Name" onChange={(e) => handleNameChange(e, 'checkedBy')} />
                        </div>
                        <div className="mb-4">
                            <Input type="text" value={formData?.checkedBy?.position} label="Position" onChange={(e) => handlePositionChange(e, 'checkedBy')} />
                        </div>
                    </div>
                    <div className="mb-4">
                        <Typography variant="h5" color="black" className="mb-2 pr-4 font-normal">
                            Noted by:
                        </Typography>
                        <div className="mb-4">
                            <Input type="text" value={formData?.notedBy?.name} label="Name" onChange={(e) => handleNameChange(e, 'notedBy')} />
                        </div>
                        <div className="mb-4">
                            <Input type="text" value={formData?.notedBy?.position} label="Position" onChange={(e) => handlePositionChange(e, 'notedBy')} />
                        </div>
                    </div>
                    
                    <Button variant="gradient" color="pink" type="submit" className="w-full">
                        {loading ? <div className="w-full flex items-center justify-center"><Loader/></div> : 'Save'}
                    </Button>
                </form>
            </Drawer>
        </>
    )
}

export default DonorsPerMonth