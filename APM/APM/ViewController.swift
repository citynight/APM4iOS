//
//  ViewController.swift
//  APM
//
//  Created by 李小争 on 2021/3/19.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        PerformanceMonitor.shared.start()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        var cellText = ""
        cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        if indexPath.row % 10 == 0 {
            usleep(200*1000)
            cellText = "模拟卡顿..."
        }else {
            cellText = "cell -- \(indexPath.row)"
        }
        cell?.textLabel?.text = cellText
        return cell!
    }
}
