//
//  LoginViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 13/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol LoginViewDelegate: BaseCoordinator {
    func successfulLogin(with login: LoginDomainModel)
}

class LoginViewController: BaseViewController, ErrorHandling {

    // MARK: Instance part
    private unowned let coordinator: LoginViewDelegate
    private let viewModel: LoginViewModel
    
    init(viewModel: LoginViewModel, coordinator: LoginViewDelegate, services: [ViewControllerService] = []) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(coordinator: coordinator, services: services)
    }

    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
    }
    
    // MARK: Helpers
    
    private let disposeBag = DisposeBag()
    
    private func setupBindings() {
        usernameTextField.placeholder = viewModel.usernameField.title
        usernameTextField.rx.text
            .orEmpty
            .bind(to: viewModel.usernameField.text)
            .disposed(by: disposeBag)
        
        usernameTextField.rx.controlEvent(.editingDidEndOnExit).subscribe { [weak self] _ in
            _ = self?.passwordTextField.becomeFirstResponder()
        }.disposed(by: disposeBag)
        
        passwordTextField.placeholder = viewModel.passwordField.title
        passwordTextField.rx.text
            .orEmpty
            .bind(to: viewModel.passwordField.text)
            .disposed(by: disposeBag)
        
        passwordTextField.passwordToggleButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.passwordField.protected.toggle()
            })
            .disposed(by: disposeBag)
        
        passwordTextField.rx.controlEvent(.editingDidEndOnExit).subscribe { [weak self] _ in
            self?.viewModel.signin()
        }.disposed(by: disposeBag)
        
        viewModel.passwordField.protected
            .bind(to: passwordTextField.protected)
            .disposed(by: disposeBag)
        
        viewModel.isValid
            .bind(to: loginButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        loginButton.rx.tap
            .do(onNext: { [weak self] in
                self?.usernameTextField.resignFirstResponder()
                self?.passwordTextField.resignFirstResponder()
            })
            .subscribe(onNext: { [weak self] in
                self?.viewModel.signin()
            })
            .disposed(by: disposeBag)
        
        viewModel.status
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                if status == .loading {
                    self?.loading.startAnimating()
                } else {
                    self?.loading.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.status
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] status in
                switch status {
                case .success:
                    self.coordinator.successfulLogin(with: self.viewModel.loginModel)
                case .error(let error):
                    self.handleError(error, okCallback: nil, retryCallback: nil)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupView() {
        view.addSubview(container)
        
        container.snp.makeConstraints { make in
            make.centerX.equalTo(safeArea)
            make.centerY.equalTo(safeArea).offset(-100)
            make.width.equalTo(200)
        }
        
        container.addSubview(logoView)
        logoView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(118)
            make.height.equalTo(160)
        }
        
        container.addSubview(usernameTextField)
        usernameTextField.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.right.left.equalToSuperview()
        }

        container.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(usernameTextField.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        container.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(40)
            make.bottom.centerX.equalToSuperview()
            make.right.left.equalToSuperview().inset(20)
        }
        
        loginButton.addSubview(loading)
        loading.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(12)
        }
        
        view.addSubview(byIkem)
        byIkem.snp.makeConstraints { make in
            make.centerX.equalTo(safeArea)
            make.bottom.equalTo(safeArea).inset(20)
            make.width.equalTo(150)
            make.height.equalTo(66)
        }
    }
    
    private lazy var logoView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "zScanner_colored")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.textContentType = .username
        textField.setBottomBorder()
        textField.font = .body
        return textField
    }()
    
    private lazy var passwordTextField: PasswordTextField = {
        let textField = PasswordTextField()
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        textField.setBottomBorder()
        textField.font = .body
        return textField
    }()

    private lazy var loginButton: PrimaryButton = {
        let button = PrimaryButton()
        button.setTitle("login.button.title".localized, for: .normal)
        return button
    }()
    
    private lazy var loading: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(style: .medium)
        loading.color = .white
        loading.hidesWhenStopped = true
        return loading
    }()
        
    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var byIkem: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "By Ikem").withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}
