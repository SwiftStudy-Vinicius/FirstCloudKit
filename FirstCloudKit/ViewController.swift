//
//  ViewController.swift
//  FirstCloudKit
//
//  Created by Vinícius Flores Ribeiro on 08/02/23.
//

import UIKit
import CloudKit

struct ItemType: Equatable {
    var name: String
    var id: CKRecord.ID
}

class ViewController: UIViewController, UITableViewDataSource {

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    private let database = CKContainer(identifier: "iCloud.myFirstContainer.CloudKitTest").publicCloudDatabase

    var items: [ItemType] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "First CloudKit"
        view.addSubview(tableView)
        tableView.dataSource = self

        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = control

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didtapAdd))
        fetchItems()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    // MARK: - Fetch
    // Vai pegar todos os itens de um determinando "recordType"
    @objc func fetchItems() {
        let query = CKQuery(recordType: "FirstItem", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            DispatchQueue.main.async {
               // self?.items = records.compactMap({ $0.value(forKey: "name") as? String})
                self?.items.removeAll()
                for record in records {
                    self?.items.append(ItemType(name: (record.value(forKey: "name") as? String)!, id: record.recordID))
                }
                self?.tableView.reloadData()
                print("fetch")
            }
        }
    }
    // MARK: - Delete
    // deleta do banco um record com um determinado ID -> CKRecord.ID
    func deleteItem(deleteItem: CKRecord.ID, indexPath: IndexPath) {
        database.delete(withRecordID: deleteItem) { recordId, error in
            DispatchQueue.main.async {
                if error != nil {
                    print(error)
                } else {
                    self.items.removeAll(where: { $0.id == deleteItem })
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    print("deleted: \(recordId)")
                }
            }
        }
    }

    // MARK: - Refresh
    // Faz o fetch dos itens e atualiza os valores da tabela
    @objc func pullToRefresh() {
        tableView.refreshControl?.beginRefreshing()
        let query = CKQuery(recordType: "FirstItem", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            DispatchQueue.main.async {
                //self?.items = records.compactMap({ $0.value(forKey: "name") as? String})
                self?.items.removeAll()
                for record in records {
                    self?.items.append(ItemType(name: (record.value(forKey: "name") as? String)!, id: record.recordID))
                }
                self?.tableView.reloadData()
                self?.tableView.refreshControl?.endRefreshing()
                print("pull to refresh")
            }
        }
    }

    // MARK: - Create item
    // cria um record com um recordType e um valor setValue()
    @objc func saveItem(name: String) {
        let record = CKRecord(recordType: "FirstItem")
        record.setValue(name, forKey: "name")
        database.save(record) { record, error in
            if record != nil, error == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    //self.pullToRefresh()
                    guard let newItem = record else { return }
                    self.items.append(ItemType(name: (newItem.value(forKey: "name") as! String), id: newItem.recordID))
                    self.tableView.reloadData()
                    print("save")
                }
            }
        }
    }

    // MARK: - Botão para adicionar um item novo
    @objc func didtapAdd() {
        let alert = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Enter Name..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            if let field = alert.textFields?.first, let text = field.text, !text.isEmpty {
                self?.saveItem(name: text)
            }
        }))
        present(alert, animated: true)
    }



    // MARK: - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteItem(deleteItem: items[indexPath.row].id, indexPath: indexPath)
            print("delete")
        }
    }

}


