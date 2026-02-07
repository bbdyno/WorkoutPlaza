//
//  RunningDetailViewController+Widgets.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers

extension RunningDetailViewController {
    
    // MARK: - Widget Configuration

    internal func configureWithWorkoutData() {
        // Check workoutData first, then importedWorkoutData, then externalWorkout
        if let data = workoutData {
            configureWithHealthKitData(data)
        } else if let imported = importedWorkoutData {
            configureWithImportedData(imported)
        } else if let external = externalWorkout {
            configureWithExternalWorkout(external)
        }
    }

    private func configureWithHealthKitData(_ data: WorkoutData) {
        // GPS 경로 데이터가 있을 때만 경로 맵 뷰 추가
        if data.hasRoute {
            let mapView = RouteMapView()
            mapView.setRoute(data.route)
            routeMapView = mapView

            // addWidget으로 추가하여 다른 위젯과 동일하게 처리
            contentView.addSubview(mapView)
            widgets.append(mapView)

            // Calculate optimal size based on route aspect ratio
            let mapSize = mapView.calculateOptimalSize(maxDimension: 280)
            let mapY: CGFloat = 70  // instructionLabel 아래 (16 + 약 34 높이 + 20)
            let mapX = (view.bounds.width - mapSize.width) / 2
            mapView.frame = CGRect(x: mapX, y: mapY, width: mapSize.width, height: mapSize.height)

            // Setup selection
            mapView.selectionDelegate = self
            selectionManager.registerItem(mapView)
            mapView.initialSize = mapSize

            // Load saved color
            if let savedColor = ColorPreferences.shared.loadColor(for: mapView.itemIdentifier) {
                mapView.applyColor(savedColor)
            }
        }

        // 기본 위젯만 생성 (거리, 시간, 평균 페이스)
        createDefaultWidgets(for: data)
    }

    private func configureWithImportedData(_ imported: ImportedWorkoutData) {
        let data = imported.originalData

        // GPS 경로 데이터가 있을 때만 경로 맵 뷰 추가
        if imported.hasRoute {
            let mapView = RouteMapView()
            mapView.setRoute(imported.routeLocations)
            routeMapView = mapView

            contentView.addSubview(mapView)
            widgets.append(mapView)

            let mapSize = mapView.calculateOptimalSize(maxDimension: 280)
            let mapY: CGFloat = 70
            let mapX = (view.bounds.width - mapSize.width) / 2
            mapView.frame = CGRect(x: mapX, y: mapY, width: mapSize.width, height: mapSize.height)

            mapView.selectionDelegate = self
            selectionManager.registerItem(mapView)
            mapView.initialSize = mapSize

            if let savedColor = ColorPreferences.shared.loadColor(for: mapView.itemIdentifier) {
                mapView.applyColor(savedColor)
            }
        }

        // 기본 위젯 생성
        createDefaultWidgetsFromImported(imported)
    }

    private func configureWithExternalWorkout(_ external: ExternalWorkout) {
        let data = external.workoutData

        // GPS 경로 데이터가 있을 때만 경로 맵 뷰 추가
        let routeLocations = data.route.map { point in
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon),
                altitude: point.alt ?? 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                timestamp: point.timestamp ?? Date()
            )
        }

        if !routeLocations.isEmpty {
            let mapView = RouteMapView()
            mapView.setRoute(routeLocations)
            routeMapView = mapView

            contentView.addSubview(mapView)
            widgets.append(mapView)

            let mapSize = mapView.calculateOptimalSize(maxDimension: 280)
            let mapY: CGFloat = 70
            let mapX = (view.bounds.width - mapSize.width) / 2
            mapView.frame = CGRect(x: mapX, y: mapY, width: mapSize.width, height: mapSize.height)

            mapView.selectionDelegate = self
            selectionManager.registerItem(mapView)
            mapView.initialSize = mapSize

            if let savedColor = ColorPreferences.shared.loadColor(for: mapView.itemIdentifier) {
                mapView.applyColor(savedColor)
            }
        }

        // 기본 위젯 생성
        createDefaultWidgetsFromExternal(external)
    }

    private func createDefaultWidgetsFromExternal(_ external: ExternalWorkout) {
        let data = external.workoutData
        let widgetSize = CGSize(width: 160, height: 80)
        let hasRoute = !data.route.isEmpty
        let startY: CGFloat = hasRoute ? 350 : 100

        // 1. 거리 위젯
        let distanceWidget = DistanceWidget()
        distanceWidget.configure(distance: data.distance)
        addWidget(distanceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY))

        // 2. 시간 위젯
        let durationWidget = DurationWidget()
        durationWidget.configure(duration: data.duration)
        addWidget(durationWidget, size: widgetSize, position: CGPoint(x: 210, y: startY))

        // 3. 페이스 위젯
        let paceWidget = PaceWidget()
        paceWidget.configure(pace: data.pace)
        addWidget(paceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY + 120))
    }

    private func createDefaultWidgetsFromImported(_ imported: ImportedWorkoutData) {
        let data = imported.originalData
        let widgetSize = CGSize(width: 160, height: 80)
        let startY: CGFloat = imported.hasRoute ? 350 : 100

        // 1. 거리 위젯
        let distanceWidget = DistanceWidget()
        distanceWidget.configure(distance: data.distance)
        addWidget(distanceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY))

        // 2. 시간 위젯
        let durationWidget = DurationWidget()
        durationWidget.configure(duration: data.duration)
        addWidget(durationWidget, size: widgetSize, position: CGPoint(x: 210, y: startY))

        // 3. 페이스 위젯
        let paceWidget = PaceWidget()
        paceWidget.configure(pace: data.pace)
        addWidget(paceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY + 120))
    }

    internal func createDefaultWidgets(for data: WorkoutData) {
        let widgetSize = CGSize(width: 160, height: 80)

        // GPS 경로가 없으면 위젯을 더 위쪽에 배치
        let startY: CGFloat = data.hasRoute ? 350 : 100

        // 1. 거리 위젯
        let distanceWidget = DistanceWidget()
        distanceWidget.configure(distance: data.distance)
        addWidget(distanceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY))

        // 2. 시간 위젯
        let durationWidget = DurationWidget()
        durationWidget.configure(duration: data.duration)
        addWidget(durationWidget, size: widgetSize, position: CGPoint(x: 210, y: startY))

        // 3. 페이스 위젯
        let paceWidget = PaceWidget()
        paceWidget.configure(pace: data.pace)
        addWidget(paceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY + 120))
    }
    
    internal func createAdditionalWidgets(for data: WorkoutData) {
        // 8. 평균 심박수 위젯 (데모용)
        let heartRateWidget = createCustomWidget(
            title: "평균 심박수",
            value: "142",
            unit: "bpm",
            icon: "heart.fill",
            color: .systemRed
        )
        addWidget(heartRateWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 30, y: 820))
        
        // 9. 고도 변화 위젯 (데모용)
        let elevationWidget = createCustomWidget(
            title: "고도 상승",
            value: "120",
            unit: "m",
            icon: "arrow.up.right",
            color: .systemGreen
        )
        addWidget(elevationWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 210, y: 820))
        
        // 10. 케이던스 위젯 (데모용)
        let cadenceWidget = createCustomWidget(
            title: "평균 케이던스",
            value: "165",
            unit: "spm",
            icon: "figure.run",
            color: .systemBlue
        )
        addWidget(cadenceWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 30, y: 940))
        
        // 11. 스트라이드 위젯 (데모용)
        let strideWidget = createCustomWidget(
            title: "평균 보폭",
            value: "1.12",
            unit: "m",
            icon: "arrow.left.and.right",
            color: .systemOrange
        )
        addWidget(strideWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 210, y: 940))
    }
    
    internal func createCustomWidget(title: String, value: String, unit: String, icon: String, color: UIColor) -> UIView {
        let widget = BaseStatWidget()
        widget.titleLabel.text = title
        widget.valueLabel.text = value
        widget.unitLabel.text = unit
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        
        widget.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return widget
    }
    
    internal func addWidget(_ widget: UIView, size: CGSize, position: CGPoint) {
        contentView.addSubview(widget)
        contentView.bringSubviewToFront(widget)
        widgets.append(widget)
        hasUnsavedChanges = true

        widget.frame = CGRect(origin: position, size: size)

        // Setup selection if widget is selectable
        if var selectableWidget = widget as? Selectable {
            selectableWidget.selectionDelegate = self
            selectionManager.registerItem(selectableWidget)

            // Set initial size for BaseStatWidget (for font scaling)
            if let statWidget = widget as? BaseStatWidget {
                statWidget.initialSize = size
            }

            // Load saved color if available
            if let savedColor = ColorPreferences.shared.loadColor(for: selectableWidget.itemIdentifier) {
                selectableWidget.applyColor(savedColor)
            }

            // Load saved font if available (only for BaseStatWidget and subclasses)
            if let statWidget = widget as? BaseStatWidget,
               let savedFont = FontPreferences.shared.loadFont(for: selectableWidget.itemIdentifier) {
                statWidget.applyFont(savedFont)
            }
        }
    }
    
    // MARK: - Widget Menu
    
    internal enum SingleWidgetType: String, CaseIterable {
        case routeMap = "경로 지도"
        case distance = "거리"
        case duration = "시간"
        case pace = "페이스"
        case speed = "속도"
        case calories = "칼로리"
        case heartRate = "심박수"
        case date = "날짜"
        case currentDateTime = "현재 날짜 및 시간"
        case text = "텍스트"
        case location = "위치"
    }
    
    internal func canAddWidget(_ type: SingleWidgetType) -> Bool {
        let hasRoute = workoutData?.hasRoute ?? importedWorkoutData?.hasRoute ?? (externalWorkout?.workoutData.route.isEmpty == false)

        switch type {
        case .routeMap:
            // GPS 경로 데이터가 없거나 이미 추가된 경우 비활성화
            return routeMapView == nil && hasRoute
        case .distance:
            return !widgets.contains(where: { $0 is DistanceWidget })
        case .duration:
            return !widgets.contains(where: { $0 is DurationWidget })
        case .pace:
            return !widgets.contains(where: { $0 is PaceWidget })
        case .speed:
            return !widgets.contains(where: { $0 is SpeedWidget })
        case .calories:
            return !widgets.contains(where: { $0 is CaloriesWidget })
        case .heartRate:
            return !widgets.contains(where: { $0 is HeartRateWidget })
        case .date:
            return !widgets.contains(where: { $0 is DateWidget })
        case .currentDateTime:
            return !widgets.contains(where: { $0 is CurrentDateTimeWidget })
        case .text:
            return true  // Multiple text widgets allowed
        case .location:
            // GPS 경로 데이터가 없거나 이미 추가된 경우 비활성화
            return !widgets.contains(where: { $0 is LocationWidget }) && hasRoute
        }
    }

    @objc internal func showAddWidgetMenu() {
        // Check if we have any data
        guard workoutData != nil || importedWorkoutData != nil || externalWorkout != nil else { return }

        let actionSheet = UIAlertController(title: "위젯 추가", message: nil, preferredStyle: .actionSheet)
        let hasRoute = workoutData?.hasRoute ?? importedWorkoutData?.hasRoute ?? (externalWorkout?.workoutData.route.isEmpty == false)

        // 1. Single Widgets
        for type in SingleWidgetType.allCases {
            let isAdded = !canAddWidget(type)
            var title = type.rawValue

            // GPS 관련 위젯에 상태 표시
            if type == .routeMap || type == .location {
                if !hasRoute {
                    title = "\(type.rawValue) (GPS 없음)"
                } else if isAdded {
                    title = "✓ \(type.rawValue)"
                }
            } else if isAdded {
                title = "✓ \(type.rawValue)"
            }

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.addSingleWidgetFromAvailableData(type)
            }

            action.isEnabled = !isAdded
            actionSheet.addAction(action)
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = addWidgetButton
            popover.sourceRect = addWidgetButton.bounds
        }

        present(actionSheet, animated: true)
    }

    internal func addSingleWidgetFromAvailableData(_ type: SingleWidgetType) {
        if let data = workoutData {
            addSingleWidget(type, data: data)
        } else if let imported = importedWorkoutData {
            addSingleWidgetFromImported(type, imported: imported)
        } else if let external = externalWorkout {
            addSingleWidgetFromExternal(type, external: external)
        }
    }
    
    internal func addSingleWidget(_ type: SingleWidgetType, data: WorkoutData) {
        var widget: UIView?
        var size = CGSize(width: 160, height: 80)

        switch type {
        case .routeMap:
            guard data.hasRoute else {
                let alert = UIAlertController(
                    title: "경로 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let mapView = RouteMapView()
            mapView.setRoute(data.route)
            routeMapView = mapView
            widget = mapView
            size = mapView.calculateOptimalSize(maxDimension: 250)

        case .distance:
            let w = DistanceWidget()
            w.configure(distance: data.distance)
            widget = w

        case .duration:
            let w = DurationWidget()
            w.configure(duration: data.duration)
            widget = w

        case .pace:
            let w = PaceWidget()
            w.configure(pace: data.pace)
            widget = w

        case .speed:
            let w = SpeedWidget()
            w.configure(speed: data.avgSpeed)
            widget = w

        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: data.calories)
            widget = w

        case .heartRate:
            let w = HeartRateWidget()
            w.configure(heartRate: data.avgHeartRate)
            widget = w

        case .date:
            let w = DateWidget()
            w.configure(startDate: data.startDate)
            widget = w

        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.startDate)
            widget = w
            size = CGSize(width: 300, height: 80)

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트 입력")
            w.textDelegate = self
            widget = w
            // Use a reasonable default size for text widget
            size = CGSize(width: 120, height: 60)

        case .location:
            guard let firstLocation = data.route.first else {
                // Show error if no GPS data
                let alert = UIAlertController(
                    title: "위치 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let w = LocationWidget()
            widget = w
            size = CGSize(width: 220, height: 50)

            // Configure asynchronously (geocoding takes time)
            w.configure(location: firstLocation) { [weak self] success in
                if success {
                    WPLog.info("Location widget configured successfully")
                } else {
                    WPLog.warning("Location widget configuration failed")
                }
            }
        }

        if let widget = widget {
            // Position in center of visible area
            let centerX = view.bounds.width / 2 - size.width / 2
            let centerY = scrollView.contentOffset.y + view.bounds.height / 2 - size.height / 2

            // For route map, use specific initial size logic if needed
            if let map = widget as? RouteMapView {
                map.initialSize = size
            }

            addWidget(widget, size: size, position: CGPoint(x: centerX, y: centerY))

            if let selectable = widget as? Selectable {
                selectionManager.selectItem(selectable)
            }
        }
    }

    private func addSingleWidgetFromImported(_ type: SingleWidgetType, imported: ImportedWorkoutData) {
        let data = imported.originalData
        var widget: UIView?
        var size = CGSize(width: 160, height: 80)

        switch type {
        case .routeMap:
            guard imported.hasRoute else {
                let alert = UIAlertController(
                    title: "경로 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let mapView = RouteMapView()
            mapView.setRoute(imported.routeLocations)
            routeMapView = mapView
            widget = mapView
            size = mapView.calculateOptimalSize(maxDimension: 250)

        case .distance:
            let w = DistanceWidget()
            w.configure(distance: data.distance)
            widget = w

        case .duration:
            let w = DurationWidget()
            w.configure(duration: data.duration)
            widget = w

        case .pace:
            let w = PaceWidget()
            w.configure(pace: data.pace)
            widget = w

        case .speed:
            let w = SpeedWidget()
            w.configure(speed: data.avgSpeed)
            widget = w

        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: data.calories)
            widget = w

        case .heartRate:
            let w = HeartRateWidget()
            w.configure(heartRate: data.avgHeartRate ?? 0)
            widget = w

        case .date:
            let w = DateWidget()
            w.configure(startDate: data.startDate)
            widget = w

        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.startDate)
            widget = w
            size = CGSize(width: 300, height: 80)

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트 입력")
            w.textDelegate = self
            widget = w
            // Use a reasonable default size for text widget
            size = CGSize(width: 120, height: 60)

        case .location:
            guard let firstLocation = imported.routeLocations.first else {
                let alert = UIAlertController(
                    title: "위치 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let w = LocationWidget()
            widget = w
            size = CGSize(width: 220, height: 50)

            w.configure(location: firstLocation) { [weak self] success in
                if success {
                    WPLog.info("Location widget configured successfully")
                } else {
                    WPLog.warning("Location widget configuration failed")
                }
            }
        }

        if let widget = widget {
            let centerX = view.bounds.width / 2 - size.width / 2
            let centerY = scrollView.contentOffset.y + view.bounds.height / 2 - size.height / 2

            if let map = widget as? RouteMapView {
                map.initialSize = size
            }

            addWidget(widget, size: size, position: CGPoint(x: centerX, y: centerY))

            if let selectable = widget as? Selectable {
                selectionManager.selectItem(selectable)
            }
        }
    }

    private func addSingleWidgetFromExternal(_ type: SingleWidgetType, external: ExternalWorkout) {
        let data = external.workoutData
        var widget: UIView?
        var size = CGSize(width: 160, height: 80)

        let routeLocations = data.route.map { point in
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon),
                altitude: point.alt ?? 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                timestamp: point.timestamp ?? Date()
            )
        }
        let hasRoute = !routeLocations.isEmpty

        switch type {
        case .routeMap:
            guard hasRoute else {
                let alert = UIAlertController(
                    title: "경로 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let mapView = RouteMapView()
            mapView.setRoute(routeLocations)
            routeMapView = mapView
            widget = mapView
            size = mapView.calculateOptimalSize(maxDimension: 250)

        case .distance:
            let w = DistanceWidget()
            w.configure(distance: data.distance)
            widget = w

        case .duration:
            let w = DurationWidget()
            w.configure(duration: data.duration)
            widget = w

        case .pace:
            let w = PaceWidget()
            w.configure(pace: data.pace)
            widget = w

        case .speed:
            let w = SpeedWidget()
            w.configure(speed: data.avgSpeed)
            widget = w

        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: data.calories)
            widget = w

        case .heartRate:
            let w = HeartRateWidget()
            w.configure(heartRate: data.avgHeartRate ?? 0)
            widget = w

        case .date:
            let w = DateWidget()
            w.configure(startDate: data.startDate)
            widget = w

        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.startDate)
            widget = w
            size = CGSize(width: 300, height: 80)

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트 입력")
            w.textDelegate = self
            widget = w
            size = CGSize(width: 120, height: 60)

        case .location:
            guard let firstLocation = routeLocations.first else {
                let alert = UIAlertController(
                    title: "위치 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let w = LocationWidget()
            widget = w
            size = CGSize(width: 220, height: 50)

            w.configure(location: firstLocation) { success in
                if success {
                    WPLog.info("Location widget configured successfully")
                } else {
                    WPLog.warning("Location widget configuration failed")
                }
            }
        }

        if let widget = widget {
            let centerX = view.bounds.width / 2 - size.width / 2
            let centerY = scrollView.contentOffset.y + view.bounds.height / 2 - size.height / 2

            if let map = widget as? RouteMapView {
                map.initialSize = size
            }

            addWidget(widget, size: size, position: CGPoint(x: centerX, y: centerY))

            if let selectable = widget as? Selectable {
                selectionManager.selectItem(selectable)
            }
        }
    }

    // MARK: - Text Path Drawing

    @objc override internal func showTextPathInput() {
        let alert = UIAlertController(
            title: "텍스트 패스",
            message: "경로를 따라 반복할 텍스트를 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "반복할 텍스트 입력"
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        alert.addAction(UIAlertAction(title: "그리기", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let text = alert?.textFields?.first?.text,
                  !text.isEmpty else { return }

            self.pendingTextForPath = text + " "
            self.enterTextPathDrawingMode()
        })

        present(alert, animated: true)
    }

    

    







    
    // MARK: - Import Workouts
    
    internal func importAsMyRecord(_ workout: ShareableWorkout) {
        let hasExistingContent = !widgets.isEmpty || !templateGroups.isEmpty || routeMapView != nil

        if hasExistingContent {
            // Show warning
            let alert = UIAlertController(
                title: "기존 내용 삭제",
                message: "내 기록으로 가져오면 현재 작성 중인 내용이 모두 사라집니다. 계속하시겠습니까?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "가져오기", style: .destructive) { [weak self] _ in
                self?.clearAllWidgetsAndImport(workout)
            })

            present(alert, animated: true)
        } else {
            // No existing content, import directly
            importWorkoutAsMyRecord(workout)
        }
    }
    
    internal func clearAllWidgetsAndImport(_ workout: ShareableWorkout) {
        // Clear all existing content
        for widget in widgets {
            widget.removeFromSuperview()
        }
        widgets.removeAll()

        for group in templateGroups {
            group.removeFromSuperview()
        }
        templateGroups.removeAll()

        routeMapView?.removeFromSuperview()
        routeMapView = nil

        selectionManager.unregisterAllItems()

        // Import as my record
        importWorkoutAsMyRecord(workout)
    }

    internal func importWorkoutAsMyRecord(_ workout: ShareableWorkout) {
        let importedData = ImportedWorkoutData(
            ownerName: "",  // Empty = my record
            originalData: workout.workout,
            selectedFields: Set(ImportField.allCases)
        )

        addImportedWorkoutGroup(importedData)
    }

    internal func showImportFieldSelectionSheet(for workout: ShareableWorkout) {
        let importVC = ImportWorkoutViewController()
        importVC.shareableWorkout = workout
        importVC.importMode = .attachToExisting
        importVC.attachToWorkout = workoutData
        importVC.delegate = self

        let navController = UINavigationController(rootViewController: importVC)
        present(navController, animated: true)
    }
    
    internal func addImportedWorkoutGroup(_ importedData: ImportedWorkoutData) {
        var importedWidgets: [UIView] = []
        let originalData = importedData.originalData

        importedWidgets = createImportedWidgetsWithDefaultLayout(importedData)

        // Create group from imported widgets if we have more than one
        guard importedWidgets.count > 1 else {
            // If only one widget, just add it to the widgets array
            widgets.append(contentsOf: importedWidgets)
            for widget in importedWidgets {
                if let selectable = widget as? Selectable {
                    selectionManager.registerItem(selectable)
                }
            }
            return
        }

        // Calculate bounding frame for all imported widgets
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for widget in importedWidgets {
            minX = min(minX, widget.frame.minX)
            minY = min(minY, widget.frame.minY)
            maxX = max(maxX, widget.frame.maxX)
            maxY = max(maxY, widget.frame.maxY)
        }

        // Add padding
        let padding: CGFloat = 16
        let groupFrame = CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + (padding * 2),
            height: maxY - minY + (padding * 2)
        )

        // Determine group type: myRecord if no owner name (createNew mode), importedRecord otherwise
        let groupType: WidgetGroupType = importedData.ownerName.isEmpty ? .myRecord : .importedRecord
        let ownerName: String? = importedData.ownerName.isEmpty ? nil : importedData.ownerName

        // Create group
        let group = TemplateGroupView(
            items: importedWidgets,
            frame: groupFrame,
            groupType: groupType,
            ownerName: ownerName
        )
        group.groupDelegate = self
        group.selectionDelegate = self
        selectionManager.registerItem(group)

        contentView.addSubview(group)
        templateGroups.append(group)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        WPLog.info("Added workout group (type: \(groupType), owner: \(ownerName ?? "self"))")
    }

    internal func createImportedWidgetsWithDefaultLayout(_ importedData: ImportedWorkoutData) -> [UIView] {
        var importedWidgets: [UIView] = []

        // Get canvas size for boundary calculations
        let canvasSize = contentView.bounds.size
        let margin: CGFloat = 20
        let spacing: CGFloat = 10

        // Calculate scale factor to fit within canvas
        let availableWidth = canvasSize.width - (margin * 2)
        let baseWidgetWidth: CGFloat = 160
        let twoColumnWidth = (baseWidgetWidth * 2) + spacing
        let scaleFactor = min(1.0, availableWidth / twoColumnWidth)

        let widgetSize = CGSize(width: baseWidgetWidth * scaleFactor, height: 80 * scaleFactor)
        let startX: CGFloat = margin

        // Find starting Y position - below existing content but within canvas
        // Start at a lower position so check button is visible (at least 80pt from top)
        let minStartY: CGFloat = 80
        var startY: CGFloat = minStartY
        for widget in widgets {
            startY = max(startY, widget.frame.maxY + spacing)
        }
        for group in templateGroups {
            startY = max(startY, group.frame.maxY + spacing)
        }
        if let routeMap = routeMapView {
            startY = max(startY, routeMap.frame.maxY + spacing)
        }

        // Ensure starting position is within canvas (with room for at least some widgets)
        let minRoomNeeded: CGFloat = 200 * scaleFactor
        if startY + minRoomNeeded > canvasSize.height {
            // Not enough room below - start at a reasonable position
            startY = max(minStartY, canvasSize.height * 0.4)
        }

        var currentY = startY

        // Add owner name label (TextWidget) - only if owner name is provided (for imported records)
        if !importedData.ownerName.isEmpty {
            let ownerWidget = TextWidget()
            ownerWidget.configure(text: "\(importedData.ownerName)의 기록")
            ownerWidget.applyColor(.systemOrange)
            ownerWidget.textDelegate = self
            let ownerSize = CGSize(width: 200 * scaleFactor, height: 40 * scaleFactor)
            ownerWidget.frame = CGRect(x: startX, y: currentY, width: ownerSize.width, height: ownerSize.height)
            ownerWidget.initialSize = ownerSize
            contentView.addSubview(ownerWidget)
            ownerWidget.selectionDelegate = self
            importedWidgets.append(ownerWidget)
            currentY += ownerSize.height + spacing
        }

        let originalData = importedData.originalData

        // Add route widget if selected and has route data
        if importedData.selectedFields.contains(.route) && importedData.hasRoute {
            let routeMap = RouteMapView()
            routeMap.setRoute(importedData.routeLocations)
            // Calculate optimal size based on route aspect ratio, constrained by canvas
            let maxRouteDimension = min(200 * scaleFactor, availableWidth * 0.6)
            let optimalSize = routeMap.calculateOptimalSize(maxDimension: maxRouteDimension)
            routeMap.frame = CGRect(x: startX, y: currentY, width: optimalSize.width, height: optimalSize.height)
            routeMap.initialSize = optimalSize
            contentView.addSubview(routeMap)
            routeMap.selectionDelegate = self
            importedWidgets.append(routeMap)
            currentY += optimalSize.height + spacing
        }

        // Add distance widget if selected
        if importedData.selectedFields.contains(.distance) {
            let w = DistanceWidget()
            w.configure(distance: originalData.distance)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Add duration widget if selected
        if importedData.selectedFields.contains(.duration) {
            let w = DurationWidget()
            w.configure(duration: originalData.duration)
            w.frame = CGRect(x: startX + widgetSize.width + spacing, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        currentY += widgetSize.height + spacing

        // Add pace widget if selected
        if importedData.selectedFields.contains(.pace) {
            let w = PaceWidget()
            w.configure(pace: originalData.pace)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Add speed widget if selected
        if importedData.selectedFields.contains(.speed) {
            let w = SpeedWidget()
            w.configure(speed: originalData.avgSpeed)
            w.frame = CGRect(x: startX + widgetSize.width + spacing, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        currentY += widgetSize.height + spacing

        // Add calories widget if selected
        if importedData.selectedFields.contains(.calories) {
            let w = CaloriesWidget()
            w.configure(calories: originalData.calories)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Add heart rate widget if selected
        if importedData.selectedFields.contains(.heartRate) {
            let w = HeartRateWidget()
            w.configure(heartRate: originalData.avgHeartRate ?? 0)
            w.frame = CGRect(x: startX + widgetSize.width + spacing, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        currentY += widgetSize.height + spacing

        // Add date widget if selected
        if importedData.selectedFields.contains(.date) {
            let w = DateWidget()
            w.configure(startDate: originalData.startDate)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Fit all imported widgets within canvas bounds
        fitImportedWidgetsToCanvas(importedWidgets, canvasSize: canvasSize, margin: margin)

        return importedWidgets
    }

    // MARK: - Canvas Fitting

    /// 가져온 위젯들이 캔버스를 벗어나면 일괄 축소하여 캔버스 내에 수용
    private func fitImportedWidgetsToCanvas(_ importedWidgets: [UIView], canvasSize: CGSize, margin: CGFloat) {
        guard !importedWidgets.isEmpty else { return }

        let totalBounds = importedWidgets.reduce(CGRect.null) { $0.union($1.frame) }
        let needsFitX = totalBounds.maxX > canvasSize.width - margin
        let needsFitY = totalBounds.maxY > canvasSize.height - margin

        guard needsFitX || needsFitY else { return }

        let fitScaleX = (canvasSize.width - margin * 2) / totalBounds.width
        let fitScaleY = (canvasSize.height - margin * 2) / totalBounds.height
        let fitScale = min(fitScaleX, fitScaleY, 1.0)

        guard fitScale < 1.0 else { return }

        for widget in importedWidgets {
            widget.frame = CGRect(
                x: margin + (widget.frame.minX - totalBounds.minX) * fitScale,
                y: margin + (widget.frame.minY - totalBounds.minY) * fitScale,
                width: widget.frame.width * fitScale,
                height: widget.frame.height * fitScale
            )
            // initialSize는 원본 크기를 유지 (덮어쓰지 않음)
            // → calculateScaleFactor()가 정확한 축소 비율을 반환하도록 함
            // RouteMapView만 initialSize 업데이트 (폰트 스케일링 불필요)
            (widget as? RouteMapView)?.initialSize = widget.frame.size
        }
    }

    // MARK: - Background Customization
    @objc override internal func changeTemplate() {
        let actionSheet = UIAlertController(title: "배경 옵션", message: nil, preferredStyle: .actionSheet)

        let templates: [(name: String, style: BackgroundTemplateView.TemplateStyle, colors: [UIColor])] = [
            ("블루 그라데이션", .gradient1, [UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0), UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)]),
            ("퍼플 그라데이션", .gradient2, [UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0)]),
            ("오렌지 그라데이션", .gradient3, [UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)]),
            ("그린 그라데이션", .gradient4, [UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0), UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)]),
            ("다크", .dark, [UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0), UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]),
            ("미니멀", .minimal, [.white])
        ]

        for template in templates {
            let action = UIAlertAction(title: template.name, style: .default) { [weak self] _ in
                self?.applyTemplate(template.style)
            }
            action.setValue(iconForGradient(colors: template.colors), forKey: "image")
            actionSheet.addAction(action)
        }

        // Random
        actionSheet.addAction(UIAlertAction(title: "랜덤", style: .default) { [weak self] _ in
            self?.backgroundTemplateView.applyRandomTemplate()
        })

        // Custom
        actionSheet.addAction(UIAlertAction(title: "커스텀 그라데이션...", style: .default) { [weak self] _ in
            self?.presentCustomGradientPicker()
        })

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = backgroundTemplateButton
            popover.sourceRect = backgroundTemplateButton.bounds
        }

        present(actionSheet, animated: true)
    }

    internal func presentCustomGradientPicker() {
        let picker = CustomGradientPickerViewController()
        picker.delegate = self
        
        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        
        present(picker, animated: true)
    }
    
    internal func iconForGradient(colors: [UIColor]) -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            
            if colors.count > 1 {
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            } else {
                colors.first?.setFill()
                path.fill()
                
                if colors.first == .white {
                    UIColor.systemGray4.setStroke()
                    path.lineWidth = 1
                    path.stroke()
                }
            }
        }
        
        return image.withRenderingMode(.alwaysOriginal)
    }
    
    internal func applyTemplate(_ style: BackgroundTemplateView.TemplateStyle) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        backgroundTemplateView.applyTemplate(style)
        dimOverlay.isHidden = true
        hasUnsavedChanges = true
    }
    
    // MARK: - 사진 선택
    @objc override internal func selectPhoto() {
        let actionSheet = UIAlertController(title: "배경 선택", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "사진 선택", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "템플릿 사용", style: .default) { [weak self] _ in
            self?.useTemplate()
        })
        
        actionSheet.addAction(UIAlertAction(title: "배경 제거", style: .destructive) { [weak self] _ in
            self?.removeBackground()
        })
        
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 지원
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = selectPhotoButton
            popover.sourceRect = selectPhotoButton.bounds
        }

        present(actionSheet, animated: true)
    }

    internal func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    internal func useTemplate() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
    }
    
    internal func removeBackground() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = true
        dimOverlay.isHidden = true
        view.backgroundColor = .systemGroupedBackground
    }
}
