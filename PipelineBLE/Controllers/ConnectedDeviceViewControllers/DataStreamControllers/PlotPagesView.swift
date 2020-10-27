//
//  PlotPagesViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 10/29/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import Charts

class PlotPagesView: UIView {
    
    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    var pageControl: UIPageControl = {
        let page = UIPageControl()
        page.translatesAutoresizingMaskIntoConstraints = false
        return page
    }()
    var emptyPageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Data Stream Not Started"
        return label
    }()
    var plots: [LineChartView]! = []
    var isAutoScrollEnabled: Bool = true
    var visibleInterval: TimeInterval = 30
    var lastUpdatedData: LineChartDataSet?
    var currentPageDisplayed: Int = 0
    var maxPlots: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //  Also add UIButton and constraints
        self.addSubview(emptyPageLabel)
        emptyPageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        emptyPageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialize(count: Int){
        //  Need to clean everything from the view
        clean()
        
        //  Let's set up the scroll view and a single chart
        maxPlots = count
        setupUI(plotCount: count, data: nil)
    }
    
    func initialize(data: [[[Double]]]){
        //  Use this function to initialize with data
        clean()
        
        //  Let's set up the plots
        maxPlots = data.count
        setupUI(plotCount: data.count, data: data)
    }
    
    func clean(){
        // Remove everything
        self.willRemoveSubview(emptyPageLabel)
        emptyPageLabel.isHidden = true
        for plot in plots{
            self.willRemoveSubview(plot)
        }
        plots.removeAll()
    }
    
    func setupUI(plotCount: Int, data: [[[Double]]]?){
        //  Adjust the UI
        scrollView.delegate = self
        
        //  Set up the scroll view
        self.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        //  Set up page control
        self.addSubview(pageControl)
        pageControl.topAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        pageControl.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        //  Set the layout subviews
        self.layoutSubviews()
        self.layoutIfNeeded()
        
        //  Now lets add plots
        if let data = data{
            // We have data to use, so pass it through
            addPlots(count: data.count, data: data)
        }
        else{
            //  No data to be used to start with
            addPlots(count: plotCount, data: nil)
        }
        
        // Init the page control w/handler for when it's scrolled
        self.pageControl.numberOfPages = plots.count
        self.pageControl.currentPage = 0
        currentPageDisplayed = 0
        pageControl.addTarget(self, action: #selector(self.changePage(_:)), for: UIControl.Event.valueChanged)
    }
    
    func addPlots(count: Int, data: [[[Double]]]?){
        //  Add the given number of plots
        for i in 0...count-1{
            //  Create the generic plot
            let plot = formattedPlot()
            plot.translatesAutoresizingMaskIntoConstraints = false
            plot.dragEnabled = !isAutoScrollEnabled
            
            //  Add the plot to list of plots and add to subview
            plots.append(plot)
            self.scrollView.addSubview(plot)
            
            
            //  Start adding constraints
            plot.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            plot.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            plot.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
            plot.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
            
            if i == 0{
                //  Just add constraint to left side for now
                plot.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            }
            else if i == count-1{
                //  At the end, so add constraint to right side = scrollview
                plot.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
                plot.leadingAnchor.constraint(equalTo: plots[i-1].trailingAnchor).isActive = true
                plots[i-1].trailingAnchor.constraint(equalTo: plot.leadingAnchor).isActive = true
            }
            else{
                plot.leadingAnchor.constraint(equalTo: plots[i-1].trailingAnchor).isActive = true
                plots[i-1].trailingAnchor.constraint(equalTo: plot.leadingAnchor).isActive = true
            }
            
            //  Now just add the data to the plot if necessary
            if let data = data{
                createPlotDataSet(data: data[i], index: i, plot: plot)
                
                //  Let's also enable dragging
                plot.dragEnabled = true
            }
        }
        
        //  Adjust the scrollview content size
        self.pageControl.numberOfPages = plots.count
        scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(plots.count), height: scrollView.frame.height)
    }
    
    func formattedPlot() -> LineChartView{
        //  Create the graph and add some preferences
        let plot = LineChartView()
        plot.borderLineWidth = 1
        plot.borderColor = .blue
        plot.translatesAutoresizingMaskIntoConstraints = false
        plot.delegate = self
        plot.chartDescription?.enabled = false
        plot.xAxis.granularityEnabled = true
        plot.xAxis.granularity = 5
        plot.leftAxis.drawZeroLineEnabled = true
        plot.legend.enabled = false
        plot.noDataText = "No data received"
        
        return plot
    }
    
    func createPlotDataSet(data: [[Double]], index: Int, plot: LineChartView){
        //  Create the dataset to be used for the plot
        var entries: [ChartDataEntry] = []
        for d in data{
            entries.append(ChartDataEntry(x: d[0], y: d[1]))
        }
        let dataSet = LineChartDataSet(entries: entries, label: "Data for static plot \(index)")
        
        //  Add some settings to the graph
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2
        
        //  Get a new color for the data set
        let colors = UartStyle.defaultColors()
        let color = colors[index % colors.count]
        dataSet.setColor(color)
            
        //  Add the data to the plot and refresh the plot
        let endData = LineChartData(dataSet: dataSet)
        plot.data = endData
        plot.data?.notifyDataChanged()
        plot.notifyDataSetChanged()
    }

    //  MARK: - Changing Page
    @objc func changePage(_ sender: Any){
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x:x, y:0), animated: true)
    }
    
    func notifyDataSetChanged(){
        let cur = currentPageDisplayed
        //  Notify that the data for this plot has changed
        plots[cur].data?.notifyDataChanged()
        plots[cur].notifyDataSetChanged()
        
        //  Make sure the visible range is accurate
        plots[cur].setVisibleXRangeMaximum(visibleInterval)
        plots[cur].setVisibleXRangeMinimum(visibleInterval)
        
        guard let dataSet = lastUpdatedData else { return }

        //  Need to adjust view depending on autoscroll
        if isAutoScrollEnabled {
            //let xOffset = Double(dataSet.entryCount) - (context.numEntriesVisible-1)
            let xOffset = (dataSet.entries.last?.x ?? 0) - (visibleInterval-1)
            plots[cur].moveViewToX(xOffset)
        }
    }
    
    func addDataSet(plotNum: Int, allData: [LineChartDataSet]){
        //  Add data to the new plot
        self.plots[plotNum].data = LineChartData(dataSets: allData)
    }
    
    func updateSlider(slider: TimeInterval){
        visibleInterval = slider
    }
    
    func updateAutoScroll(){
        isAutoScrollEnabled = !isAutoScrollEnabled
        plots[currentPageDisplayed].dragEnabled = !isAutoScrollEnabled
    }
    
    @objc func reloadData(){
        DispatchQueue.main.async {
            self.notifyDataSetChanged()
        }
    }
}

//  MARK: - Scroll View Delegate
extension PlotPagesView: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
        currentPageDisplayed = Int(pageNumber)
    }
    
    func changePage(){
        //  Just go to the next page if possible
        if pageControl.currentPage != pageControl.numberOfPages {
            pageControl.currentPage = Int(pageControl.currentPage + 1)
            currentPageDisplayed = pageControl.currentPage
            self.changePage(self)
            self.notifyDataSetChanged()
        }
    }
    
    func changePage(toPage: Int){
        //  Go to the indicated page
        if toPage < pageControl.numberOfPages, toPage >= 0 {
            pageControl.currentPage = Int(toPage)
            currentPageDisplayed = pageControl.currentPage
            self.changePage(self)
            self.notifyDataSetChanged()
        }
    }
}

//  MARK: - Chart View Delegate
extension PlotPagesView: ChartViewDelegate{

}
